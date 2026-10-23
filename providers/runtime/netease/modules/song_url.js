// Generated from ../netease/modules/song_url.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 获取歌曲播放地址（v1 端点，level 而非裸 br）
 *
 * params:
 * - id / ids   歌曲 id（单个或逗号分隔）
 * - level      音质 level，默认 exhigh（320k MP3）
 *              standard / exhigh / lossless / hires / jyeffect / sky / jymaster
 *
 * 响应：`{ code, data: [{ id, url, br, level, freeTrialInfo, ... }] }`
 * - url == null：VIP / 版权未开放
 * - freeTrialInfo != null：仅 30s 试听片段
 */

import { cookieToJson } from "../core/cookie.js";
import { createOption } from "../core/option.js";
                                                      

const song_url                = (query, request) => {
  const ids = query.id ?? query.ids;
  const level = String(query.level ?? "exhigh");
  const data                          = {
    ids: `[${String(ids).split(",").join(",")}]`,
    level,
    encodeType: "flac",
  };
  if (level === "sky") {
    data.immerseType = query.immerseType ?? "c51";
  }
  const option = createOption(query, "xeapi");
  if (level === "vivid") {
    data.encodeType = "mp3";
    const cookie = option.cookie;
    option.cookie = {
      ...(typeof cookie === "string" ? cookieToJson(cookie) : cookie),
      os: "android",
      appver: "9.5.61",
    };
  }
  return request("/api/song/enhance/player/url/v1", data, option);
};

export default song_url;
