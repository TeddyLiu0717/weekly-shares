# Weekly Shares Roadmap

Updated: 2026-10-29

## Phase 1: 初始化与第一期（completed）

- 按 foundation 规范建立项目骨架与全套治理文件
- 论坛 CLI 具备 upload / publishmd（素材自动上传、429 退避、MD5 缓存）
- 第一期《AI 知识库搭建》成稿：7 图 + 45 秒演示视频，已存论坛私有草稿
- 配套开源脚手架 https://github.com/TeddyLiu0717/ai-kb-starter
- 发布 SOP、素材规范、帖子模板、选题池就位

## Phase 2: 跑通周更节奏（P0）

1. 第一期公开发布并回填 meta.json（forum_topic_id / forum_url / 发布时间）
2. 连续 4 周按 SOP 出刊，打磨模板，把单期生产时间压到 2 小时内
3. 每期发布后做一次轻量复盘（数据：浏览/点赞/评论；写入期目录 RETRO.md）
4. 建立固定栏目心智（如：实践沉淀 / 工具干货 / 踩坑复盘 轮换）

## Phase 3: 半自动化（P1）

1. 周度选题提醒：每周固定时间从 ideas/BACKLOG.md 挑题并生成初稿大纲（草稿）
2. 配图组件化：沉淀可复用的 HTML 场景模板（封面/架构/流程/终端/结尾 CTA）
3. 发布清单脚本化：`tools\publish-check.ps1` 校验 meta 完整性、素材齐全、链接非本地路径
4. 评论回收：定期用 CLI reply 维护评论互动

## Phase 4: 资产化（P2）

1. 帖子与个人知识库（ai-kb-starter 体系）双向联动：沉淀 → 分享 → 反馈再入库
2. 优质内容合集页 / 年度索引
3. 评估多平台分发（只在流程稳定后）

## 需要 Teddy 决策

- 第一期是否按现稿发布（草稿已在论坛）
- 周更固定日期（建议周四成文、周五发布）
- 远程仓库公开还是私有（当前初始化即推送公开仓库）
