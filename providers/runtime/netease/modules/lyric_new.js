// Generated from ../netease/modules/lyric_new.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 歌词（新版，含逐字歌词 yrc）
 * params:
 * - id  歌曲 id
 */

import { createOption } from "../core/option.js";
                                                      

const lyric_new                = (query, request) => {
  const data = {
    id: query.id,
    cp: false,
    tv: 0,
    lv: 0,
    rv: 0,
    kv: 0,
    yv: 0,
    ytv: 0,
    yrv: 0,
  };
  return request("/api/song/lyric/v1", data, createOption(query));
};

export default lyric_new;
