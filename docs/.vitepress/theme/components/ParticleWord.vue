<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useData } from 'vitepress'

const FONT = 'Fraunces, Palatino, "Iowan Old Style", serif'
const PRIMARY = 'flutter-'
const ACCENT = 'cookbook'

type Particle = {
  x: number
  y: number
  tx: number
  ty: number
  vx: number
  vy: number
  accent: boolean
}

type Run = {
  text: string
  italic: boolean
  accent: boolean
  x: number
  y: number
}

const host = ref<HTMLElement | null>(null)
const canvasRef = ref<HTMLCanvasElement | null>(null)
const failed = ref(false)

const { isDark } = useData()

let particles: Particle[] = []
let cssW = 0
let cssH = 0
let radius = 1.6
let repulseRadius = 120
let repulseStrength = 8
let ink = '#2a211c'
let gold = '#9a6b2f'
let introduced = false
let running = false
let raf = 0
let generation = 0
let hovering = false
let clientX = -9999
let clientY = -9999
let reduced = false

const spring = 0.05
const friction = 0.84

let resizeObserver: ResizeObserver | null = null
let observedWidth = 0
let reducedQuery: MediaQueryList | null = null
let removePointer: (() => void) | null = null

function fontString(size: number, italic: boolean) {
  return `${italic ? 'italic ' : ''}600 ${size}px ${FONT}`
}

function applyFont(ctx: CanvasRenderingContext2D, size: number, italic: boolean) {
  ctx.font = fontString(size, italic)
  const spaced = ctx as CanvasRenderingContext2D & { letterSpacing?: string }
  if ('letterSpacing' in ctx) spaced.letterSpacing = '-0.03em'
}

function readColors() {
  const el = host.value
  if (!el) return
  const style = getComputedStyle(el)
  ink = style.getPropertyValue('--pw-ink').trim() || ink
  gold = style.getPropertyValue('--pw-gold').trim() || gold
}

function leftBudget(el: HTMLElement) {
  const home = el.closest('.VPHome') as HTMLElement | null
  const edge = (home ?? el).getBoundingClientRect().left
  const margin = Number.parseFloat(getComputedStyle(el).marginLeft) || 0
  const contentLeft = el.getBoundingClientRect().left - margin
  return Math.max(0, Math.floor(contentLeft - edge - 2))
}

function measureRun(ctx: CanvasRenderingContext2D, text: string, size: number, italic: boolean) {
  applyFont(ctx, size, italic)
  const metrics = ctx.measureText(text)
  return {
    width: metrics.width,
    ascent: metrics.actualBoundingBoxAscent || size * 0.8,
    descent: metrics.actualBoundingBoxDescent || size * 0.22,
  }
}

async function ensureFont(size: number) {
  if (!document.fonts?.load) return
  await Promise.all([
    document.fonts.load(fontString(size, false)),
    document.fonts.load(fontString(size, true)),
  ])
}

function layoutText(
  ctx: CanvasRenderingContext2D,
  parentWidth: number,
  bleedX: number,
) {
  const rightBleed = Math.round(Math.min(64, Math.max(18, parentWidth * 0.05)))
  const maxText = Math.max(160, parentWidth - rightBleed)

  const widthAt = (size: number) => {
    const a = measureRun(ctx, PRIMARY, size, false)
    const b = measureRun(ctx, ACCENT, size, true)
    return { a, b, width: a.width + b.width + size * 0.02 }
  }

  let size = Math.min(112, Math.max(64, parentWidth * 0.1))
  let single = widthAt(size)
  while (size > 60 && single.width > maxText) {
    size -= 2
    single = widthAt(size)
  }

  const twoLine = single.width > maxText
  if (twoLine) {
    size = Math.min(84, Math.max(48, parentWidth * 0.2))
    const fits = (value: number) => {
      const a = measureRun(ctx, PRIMARY, value, false)
      const b = measureRun(ctx, ACCENT, value, true)
      return Math.max(a.width, b.width) <= maxText
    }
    while (size > 36 && !fits(size)) size -= 2
  }

  const primary = measureRun(ctx, PRIMARY, size, false)
  const accent = measureRun(ctx, ACCENT, size, true)
  const ascent = Math.max(primary.ascent, accent.ascent)
  const descent = Math.max(primary.descent, accent.descent)
  const topBleed = Math.round(rightBleed * 0.72)
  const bottomBleed = rightBleed
  const runs: Run[] = []
  let textWidth = 0
  let height = 0

  if (!twoLine) {
    const gap = size * 0.02
    textWidth = primary.width + gap + accent.width
    const baseline = topBleed + ascent
    runs.push(
      { text: PRIMARY, italic: false, accent: false, x: bleedX, y: baseline },
      { text: ACCENT, italic: true, accent: true, x: bleedX + primary.width + gap, y: baseline },
    )
    height = Math.ceil(baseline + descent + bottomBleed)
  } else {
    textWidth = Math.max(primary.width, accent.width)
    const baseline = topBleed + ascent
    const next = baseline + ascent + descent + size * 0.16
    runs.push(
      { text: PRIMARY, italic: false, accent: false, x: bleedX, y: baseline },
      { text: ACCENT, italic: true, accent: true, x: bleedX, y: next },
    )
    height = Math.ceil(next + descent + bottomBleed)
  }

  const inkArea = textWidth * size * 0.42
  const step = Math.max(3, Math.min(4, Math.round(Math.sqrt(inkArea / 2600))))
  const influence = Math.round(Math.min(140, Math.max(86, size * 1.22)))

  return {
    cssW: Math.ceil(bleedX + textWidth + rightBleed),
    cssH: height,
    fontSize: size,
    runs,
    step,
    repulseRadius: influence,
    repulseStrength: size * 0.085,
  }
}

function sample(
  runs: Run[],
  width: number,
  height: number,
  fontSize: number,
  step: number,
) {
  const sampleCanvas = document.createElement('canvas')
  sampleCanvas.width = width
  sampleCanvas.height = height
  const ctx = sampleCanvas.getContext('2d', { willReadFrequently: true })
  if (!ctx) return [] as Particle[]

  ctx.clearRect(0, 0, width, height)
  ctx.textBaseline = 'alphabetic'
  for (const run of runs) {
    applyFont(ctx, fontSize, run.italic)
    ctx.fillStyle = run.accent ? '#ff0000' : '#000000'
    ctx.fillText(run.text, run.x, run.y)
  }

  const { data } = ctx.getImageData(0, 0, width, height)
  const next: Particle[] = []
  const scatter = !reduced && !introduced
  for (let row = 0, y = 0; y < height; y += step, row += 1) {
    const xOffset = row % 2 === 0 ? 0 : Math.floor(step / 2)
    for (let x = xOffset; x < width; x += step) {
      let count = 0
      let sx = 0
      let sy = 0
      let accentVotes = 0
      const xEnd = Math.min(width, x + step)
      const yEnd = Math.min(height, y + step)
      for (let yy = y; yy < yEnd; yy += 1) {
        const rowStart = yy * width
        for (let xx = x; xx < xEnd; xx += 1) {
          const index = (rowStart + xx) * 4
          const alpha = data[index + 3]
          if (alpha < 150) continue
          count += 1
          sx += xx
          sy += yy
          if (data[index] > 140) accentVotes += 1
        }
      }
      if (!count) continue
      const tx = sx / count + 0.5
      const ty = sy / count + 0.5
      const particle: Particle = {
        x: tx,
        y: ty,
        tx,
        ty,
        vx: 0,
        vy: 0,
        accent: accentVotes > count * 0.45,
      }
      if (scatter) {
        const angle = Math.random() * Math.PI * 2
        const mag = fontSize * (0.18 + Math.random() * 0.42)
        particle.x = Math.min(width - 1, Math.max(1, tx + Math.cos(angle) * mag))
        particle.y = Math.min(height - 1, Math.max(1, ty + Math.sin(angle) * mag))
        particle.vx = (Math.random() - 0.5) * 1.4
        particle.vy = (Math.random() - 0.5) * 1.4
      }
      next.push(particle)
    }
  }
  return next
}

function pointer() {
  const canvas = canvasRef.value
  if (!canvas || !hovering) return { x: 0, y: 0, on: false }
  const rect = canvas.getBoundingClientRect()
  const x = clientX - rect.left
  const y = clientY - rect.top
  const reach = repulseRadius * 0.35
  const on = x > -reach && y > -reach && x < rect.width + reach && y < rect.height + reach
  return { x, y, on }
}

function step() {
  const mouse = pointer()
  const reach = repulseRadius
  const reachSq = reach * reach
  let energy = 0
  for (const particle of particles) {
    if (mouse.on) {
      const dx = particle.x - mouse.x
      const dy = particle.y - mouse.y
      const distSq = dx * dx + dy * dy
      if (distSq < reachSq && distSq > 0.01) {
        const dist = Math.sqrt(distSq)
        const falloff = (reach - dist) / reach
        const push = falloff * falloff * repulseStrength
        particle.vx += (dx / dist) * push
        particle.vy += (dy / dist) * push
      }
    }
    particle.vx += (particle.tx - particle.x) * spring
    particle.vy += (particle.ty - particle.y) * spring
    particle.vx *= friction
    particle.vy *= friction
    particle.x += particle.vx
    particle.y += particle.vy
    energy += particle.vx * particle.vx + particle.vy * particle.vy
  }
  return energy
}

function draw() {
  const canvas = canvasRef.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  if (!ctx) return
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  ctx.clearRect(0, 0, cssW, cssH)

  const paint = (accent: boolean, color: string) => {
    ctx.beginPath()
    for (const particle of particles) {
      if (particle.accent !== accent) continue
      ctx.moveTo(particle.x + radius, particle.y)
      ctx.arc(particle.x, particle.y, radius, 0, Math.PI * 2)
    }
    ctx.fillStyle = color
    ctx.fill()
  }

  paint(false, ink)
  paint(true, gold)
}

function kick() {
  if (running || reduced) return
  running = true
  raf = requestAnimationFrame(frame)
}

function frame() {
  if (document.hidden) {
    running = false
    return
  }
  const energy = step()
  draw()
  if (energy < particles.length * 0.0008) {
    running = false
    return
  }
  raf = requestAnimationFrame(frame)
}

async function rebuild() {
  const el = host.value
  const canvas = canvasRef.value
  const parent = el?.parentElement
  if (!el || !canvas || !parent) return
  const width = parent.clientWidth
  if (width < 80) return
  observedWidth = width

  const gen = ++generation
  const scratch = document.createElement('canvas').getContext('2d')
  if (!scratch) {
    failed.value = true
    return
  }

  const probe = Math.min(112, Math.max(48, width * 0.1))
  await ensureFont(probe)
  if (gen !== generation) return

  const bleedX = Math.min(64, leftBudget(el), Math.round(Math.max(20, width * 0.05)))
  el.style.setProperty('--pw-bleed', `${bleedX}px`)
  const layout = layoutText(scratch, width, bleedX)
  await ensureFont(layout.fontSize)
  if (gen !== generation) return

  cssW = layout.cssW
  cssH = layout.cssH
  radius = Math.max(1.25, layout.step * 0.48)
  repulseRadius = layout.repulseRadius
  repulseStrength = layout.repulseStrength

  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  canvas.width = Math.ceil(cssW * dpr)
  canvas.height = Math.ceil(cssH * dpr)
  canvas.style.width = `${cssW}px`
  canvas.style.height = `${cssH}px`

  readColors()
  particles = sample(layout.runs, cssW, cssH, layout.fontSize, layout.step)
  if (!particles.length) {
    failed.value = true
    return
  }
  failed.value = false
  introduced = true
  if (reduced) draw()
  else kick()
}

function onPointerMove(event: PointerEvent) {
  clientX = event.clientX
  clientY = event.clientY
  hovering = true
  kick()
}

function onPointerUp(event: PointerEvent) {
  if (event.pointerType !== 'touch') return
  hovering = false
  kick()
}

function onPointerLeave() {
  hovering = false
  kick()
}

function onReducedChange() {
  reduced = !!reducedQuery?.matches
  if (reduced) {
    running = false
    cancelAnimationFrame(raf)
    for (const particle of particles) {
      particle.x = particle.tx
      particle.y = particle.ty
      particle.vx = 0
      particle.vy = 0
    }
    draw()
    return
  }
  kick()
}

onMounted(() => {
  const el = host.value
  if (!el) return
  reducedQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
  reduced = reducedQuery.matches
  reducedQuery.addEventListener('change', onReducedChange)

  window.addEventListener('pointermove', onPointerMove, { passive: true })
  window.addEventListener('pointerup', onPointerUp, { passive: true })
  window.addEventListener('blur', onPointerLeave)
  document.documentElement.addEventListener('mouseleave', onPointerLeave)
  document.addEventListener('visibilitychange', kick)
  removePointer = () => {
    window.removeEventListener('pointermove', onPointerMove)
    window.removeEventListener('pointerup', onPointerUp)
    window.removeEventListener('blur', onPointerLeave)
    document.documentElement.removeEventListener('mouseleave', onPointerLeave)
    document.removeEventListener('visibilitychange', kick)
  }

  const parent = el.parentElement
  if (parent) {
    resizeObserver = new ResizeObserver(() => {
      const next = parent.clientWidth
      if (Math.abs(next - observedWidth) < 2) return
      void rebuild()
    })
    resizeObserver.observe(parent)
  }
  void rebuild()
})

watch(isDark, async () => {
  await Promise.resolve()
  readColors()
  if (reduced || !running) draw()
})

onBeforeUnmount(() => {
  generation += 1
  running = false
  cancelAnimationFrame(raf)
  resizeObserver?.disconnect()
  reducedQuery?.removeEventListener('change', onReducedChange)
  removePointer?.()
})
</script>

<template>
  <div ref="host" class="particle-word" aria-hidden="true">
    <p v-if="failed" class="brand particle-fallback">
      <span class="brand-flutter">flutter</span><span class="brand-dash">-</span><span class="brand-book">cookbook</span>
    </p>
    <canvas v-show="!failed" ref="canvasRef" />
  </div>
</template>

<style scoped>
.particle-word {
  --pw-ink: #2a211c;
  --pw-gold: var(--brand-cook, #9a6b2f);
  width: fit-content;
  max-width: calc(100% + var(--pw-bleed, 0px));
  margin: 0 0 0.15rem calc(var(--pw-bleed, 0px) * -1);
  line-height: 0;
  min-height: 6.5rem;
  user-select: none;
}

canvas {
  display: block;
  touch-action: pan-y;
}

.particle-fallback {
  margin: 0;
  line-height: 0.95;
  font-size: clamp(2.6rem, 8vw, 6.5rem);
}

@media (min-width: 40rem) {
  .particle-word {
    min-height: 8.5rem;
  }
}

@media (min-width: 60rem) {
  .particle-word {
    min-height: 10.5rem;
  }
}

</style>
