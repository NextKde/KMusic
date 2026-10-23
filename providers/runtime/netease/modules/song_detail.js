// Generated from ../netease/modules/song_detail.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 获取歌曲详情
 *
 * params:
 * - ids   歌曲 id（单个或逗号分隔）
 *
 * 响应：`{ code, songs: [{ id, name, ar, al, dt, ... }], privileges: [...] }`
 */

import { createOption } from "../core/option.js";
                                                      

const song_detail                = (query, request) => {
  const ids = String(query.ids ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const data = {
    c: `[${ids.map((id) => `{"id":${id}}`).join(",")}]`,
  };
  return request("/api/v3/song/detail", data, createOption(query));
};

export default song_detail;
