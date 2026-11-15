// 工程级 hvigor 脚本入口（系统内置，不可修改 system 字段）
import { appTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks, /* 内置插件，用于构建整个应用 */
  plugins: []       /* 自定义插件（本项目无需） */
}
