import axios, { InternalAxiosRequestConfig, AxiosResponse, AxiosError, AxiosRequestConfig, AxiosInstance } from '@ohos/axios';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS';
import { PreferencesUtil } from '@pura/harmony-utils';

interface ApiResponse<T> {
  data: T;
  message?: string;
  code?: string; // 统一为字符串类型
  msg?: string;
}

// 创建 axios 实例
const instance: AxiosInstance = axios.create({
  baseURL: 'https://zhdj.changhong.com',
  timeout: 10000, // 10秒超时
  headers: { 'Content-Type': 'application/json' },
});

// 设置请求拦截器
instance.interceptors.request.use(async (config: InternalAxiosRequestConfig) => {
  console.log('instance.interceptors.request:', JSON.stringify(config));

  // 从 PreferencesUtils 中异步获取 token
  const token = await PreferencesUtil.get("token", '');
  console.log('instance.interceptors.request:token:', token);

  if (token) {
    config.headers['Authorization'] = "Bearer " + token; // 设置 token
    config.headers['System-id'] = "3";
  }

  return config;
}, (error: AxiosError) => {
  // 请求错误处理
  return Promise.reject(error);
});

// 设置响应拦截器
instance.interceptors.response.use((response: AxiosResponse) => {
  console.log('cwx-response:', JSON.stringify(response));

  // 根据项目的实际情况处理响应
  if (response?.data?.code === '500') {
    promptAction.showToast({
      message: response.data.message, // 修正拼写错误
      duration: 500,
      alignment: Alignment.Center
    });
    return Promise.reject(response.data);
  }

  if (response?.data?.code === '200') {
    return Promise.resolve(response.data);
  }






  return response.data;
}, (error: AxiosError) => {
  console.log('AxiosError:', JSON.stringify(error.response));

  const status = error.response?.status;
  switch (status) {
    case 401: // 无权限未登录
      router.pushUrl({
        url: 'pages/login'
      });
      break;
    default:
      promptAction.showToast({
        message: '系统异常，请稍后再试！',
        duration: 2000,
        alignment: Alignment.Center
      });
      break;
  }

  return Promise.reject(error);
});

// 暴露封装请求--每次调用这个方法时，不会重复添加拦截器
export default <T>(config: AxiosRequestConfig): Promise<ApiResponse<T>> => {
  return instance(config);
};
