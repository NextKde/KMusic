// Generated from ../netease/modules/login_qr_key.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 获取二维码登录 unikey
 */

import { createOption } from "../core/option.js";
                                                      

const loginQrKey                = async (query, request) => {
  const result = await request("/api/login/qrcode/unikey", { type: 3 }, createOption(query));
  return {
    status: 200,
    body: { data: result.body, code: 200 },
    cookie: result.cookie,
  };
};

export default loginQrKey;
