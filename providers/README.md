# NetEase provider runtime

The application launches `runtime/helper.js` with ordinary Node.js 22.19+.
It does not execute TypeScript, require npm packages, or require Node's optional
TypeScript support. Some distro Node builds disable TypeScript even when their
version is recent enough; version checking alone cannot detect that limitation.

The original, editable TypeScript sources remain in this directory. The checked-in
`runtime/` files are generated from them; original comments and the NetEase
license/NOTICE are retained. `runtime/manifest.json` records source and artifact
hashes, plus the build-tool Node version.

Only developers changing provider TypeScript need a Node build with
[`stripTypeScriptTypes`](https://nodejs.org/download/release/v22.18.0/docs/api/module.html#modulestriptypescripttypescode-options):

```sh
node tools/build-provider-runtime.mjs
node tests/provider_runtime.mjs
```

Run from the repository root. End-user source installation uses the committed
JavaScript and does not regenerate it. The regression test checks source/artifact
hashes, starts the actual helper without TS flags, and checks empty-session and
login-required responses without network calls or account credentials.

## 中文

应用启动普通 JavaScript 文件 `runtime/helper.js`，保留 Node 22.19+ 要求，
不依赖 Node 是否编译了 TypeScript 支持，也不需要 npm install。
只有修改 TypeScript 源码的开发者需要使用具备类型剥离功能的 Node 重新生成运行文件。
原始源码、许可和来源说明一并保留；manifest 与回归测试用于发现忘记重新生成的情况。
