import { defineConfig } from 'vitepress'

const pages = process.env.GITHUB_PAGES === 'true'
const base = pages ? '/flutter_example/' : '/'

export default defineConfig({
  lang: 'zh-CN',
  title: 'flutter-cookbook',
  description: 'Package 模板工程集，记录 Package 的使用。',
  lastUpdated: true,
  // 项目页地址是 /flutter_example/。GitHub Pages 不会把 /foo 转到 foo.html，线上关闭 cleanUrls。
  base,
  cleanUrls: !pages,
  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}logo.svg` }],
  ],

  themeConfig: {
    logo: '/logo.svg',
    siteTitle:
      '<span class="brand"><span class="brand-flutter">flutter</span><span class="brand-dash">-</span><span class="brand-book">cookbook</span></span>',

    nav: [
      { text: '指南', link: '/guide/', activeMatch: '/guide/' },
    ],

    sidebar: [
      {
        text: '指南',
        items: [
          { text: '项目介绍', link: '/guide/' },
          { text: 'launch.json', link: '/guide/launch' },
          { text: '脚本', link: '/guide/scripts' },
          { text: '贡献与问题', link: '/guide/contributing' },
        ],
      },
      {
        text: '存储',
        items: [
          { text: 'ObjectBox', link: '/database/objectbox' },
          { text: 'Realm', link: '/database/realm' },
          { text: 'Drift', link: '/database/drift' },
          { text: 'sqflite', link: '/database/sqflite' },
        ],
      },
      {
        text: '状态管理',
        items: [
          { text: 'Provider', link: '/state/provider' },
          { text: 'GetX', link: '/state/getx' },
          { text: 'Bloc / Cubit', link: '/state/bloc' },
          { text: 'Riverpod', link: '/state/riverpod' },
          { text: 'Async Redux', link: '/state/redux' },
          { text: 'Signals', link: '/state/signals' },
        ],
      },
      {
        text: '其他',
        items: [{ text: 'flutter_rust_bridge', link: '/rust/' }],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/ArturoYi/flutter_example' },
    ],

    outline: {
      level: [2, 3],
      label: '本页目录',
    },

    docFooter: {
      prev: '上一页',
      next: '下一页',
    },

    darkModeSwitchLabel: '外观',
    lightModeSwitchTitle: '切换到浅色模式',
    darkModeSwitchTitle: '切换到深色模式',
    sidebarMenuLabel: '菜单',
    returnToTopLabel: '回到顶部',

    lastUpdated: {
      text: '最后更新于',
    },

    search: {
      provider: 'local',
      options: {
        translations: {
          button: {
            buttonText: '搜索',
            buttonAriaLabel: '搜索',
          },
          modal: {
            noResultsText: '没有找到结果',
            resetButtonTitle: '清除',
            footer: {
              selectText: '选择',
              navigateText: '切换',
              closeText: '关闭',
            },
          },
        },
      },
    },

    footer: {
      message: 'MIT 许可证',
      copyright: 'Copyright © 2026',
    },
  },
})
