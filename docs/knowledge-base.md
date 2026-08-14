# fzf-mru 知识库

本仓库相关的非显而易见经验记录（代码改动本身见 git/commit，不在此重复）。

## 配置位置

- **fzf/插件配置放在 `vimrc/plugin/plugins_config.vim`，不要放顶层 `vimrc`**。
  `$FZF_DEFAULT_OPTS`、`g:fzf_mru_*`、`g:fzf_action`、键位映射等都集中在这里
  （用户明确纠正过）。顶层的 `vimrc` 只放全局/编辑器设置。

## 扩展 fzf-mru 的设计取向

- **复刻 fzf.vim 的私有函数，而不是改 fzf.vim**。fzf.vim 的 `s:build_hint()`
  （`--footer` 键位提示渲染器）是脚本私有的 `s:` 函数、无公开接口，只供 fzf.vim
  自带命令（Buffers/Commits/History）内部调用；fzf-mru 走 `fzf#wrap`/`fzf#run`，
  fzf.vim 不会自动加 footer。改 `junegunn/fzf.vim` 不是改我们自己的 fork，插件更新
  会被覆盖。用户选了"保持复刻"：在 fzf-mru 里复制一份小的私有函数（格式/配色与
  fzf.vim 一致即可）。代价：上游改了对应函数时会漂移，需注意同步。

## fzf 分屏排查

- **"ctrl-v / ctrl-x 不分屏"基本是假象**：fzf.vim 的 `s:common_sink` 在"当前窗口
  已有文件打开"时才真正分屏/新标签；若当前 buffer 为空（未打开文件、单行空、未修改），
  它会故意走 `:e <file>` 直接替换空 buffer，而不分屏。排查时务必让当前窗口先打开一个
  真实文件再测（headless 空 buffer 下 `winnr('$')` 不增长只是假阴性）。fzf-mru 的
  `s:sink` 委托给 `fzf#wrap` 的 `s:common_sink`（覆写 `spec['sink*']` 前捕获为
  `l:Original`），所以分屏分发行为与 fzf.vim 自带命令一致。

## 仓库身份与提交规范

- 本仓库是用户的个人 fork：`github.com:ououmania/fzf-mru.vim.git`，分支 `master`，
  直接 push 到 `origin/master`。多次改动合并为**单个压合 commit** 再提交。
