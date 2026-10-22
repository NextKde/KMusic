/**
 * 获取二维码登录 unikey
 */

import { createOption } from "../core/option.ts";
import type { NeteaseModule } from "../core/types.ts";

const loginQrKey: NeteaseModule = async (query, request) => {
  const result = await request("/api/login/qrcode/unikey", { type: 3 }, createOption(query));
  return {
    status: 200,
    body: { data: result.body, code: 200 },
    cookie: result.cookie,
  };
};

export default loginQrKey;
