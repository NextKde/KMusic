/**
 * 轮询二维码扫码状态
 * - 801 待扫码、802 待确认、800 已过期、803 已确认（此时 cookie 里有 MUSIC_U）
 */

import { createOption } from "../core/option.ts";
import type { NeteaseModule } from "../core/types.ts";

const loginQrCheck: NeteaseModule = async (query, request) => {
  const data = { key: query.key, type: 3 };
  try {
    const result = await request("/api/login/qrcode/client/login", data, createOption(query));
    return {
      status: 200,
      body: { ...result.body, cookie: result.cookie.join(";") },
      cookie: result.cookie,
    };
  } catch (err) {
    // KMusic: preserve real QR states; propagate network/protocol failures.
    const failure = err as { response?: { status: number; body: Record<string, unknown>; cookie: string[] } };
    if (failure.response && [800, 801, 802, 803].includes(Number(failure.response.body.code)))
      return failure.response;
    throw err;
  }
};

export default loginQrCheck;
