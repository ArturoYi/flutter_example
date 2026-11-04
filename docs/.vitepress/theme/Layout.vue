<script setup lang="ts">
import DefaultTheme from 'vitepress/theme'
import { useData } from 'vitepress'
import ParticleWord from './components/ParticleWord.vue'

const { Layout } = DefaultTheme
const { frontmatter } = useData()
</script>

<template>
  <Layout>
    <template #home-hero-info-before>
      <ParticleWord v-if="frontmatter.hero" />
    </template>
  </Layout>
</template>
