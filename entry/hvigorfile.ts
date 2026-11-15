// 模块级 hvigor 脚本入口（系统内置，不可修改 system 字段）
import { hapTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: hapTasks, /* 内置插件，用于构建 HAP */
  plugins: []       /* 自定义插件（本项目无需） */
}
