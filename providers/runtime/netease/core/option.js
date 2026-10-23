// Generated from ../netease/core/option.ts by tools/build-provider-runtime.mjs; edit the TS source.
/** 从业务参数中提取请求层配置 */

                                              
                                                   

/** 调用方传入的可选参数 */
                        
                        
                 
             
                      
                            
                                           
                       
              
                                           
                  
                                           
              
                                     
                
                         
                  
                              
                                
               
                         
 

/**
 * 创建请求 options
 * @param query - 调用方传入的可选参数
 * @param crypto - 加密方式
 * @param checkToken - 是否附加 anti-cheat token（如 "v3"）
 * @returns 请求 options
 */
export const createOption = (
  query       ,
  crypto                  = "",
  checkToken                   = false,
)                 => ({
  client: query.client,
  crypto: (query.crypto                          ) || crypto,
  cookie: query.cookie,
  ua: query.ua || "",
  realIP: query.realIP,
  ip: query.ip,
  e_r: query.e_r,
  domain: query.domain || "",
  checkToken: query.checkToken || checkToken,
});

/**
 * 为浏览器环境提供一致的请求配置，SDK 是否启用由路径规则决定
 * @param query - 业务接口接收到的请求参数
 * @returns 使用网页加密与公共会话的请求配置
 */
export const createWebOption = (query       )                 => ({
  ...createOption(query, "weapi"),
  crypto: "weapi",
  client: "web",
});
