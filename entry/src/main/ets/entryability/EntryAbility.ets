// entryability/EntryAbility.ets
// 应用入口 Ability：负责加载主页，并处理卡片点击跳转（router 事件）。
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  // 目标页面路由（默认主页）
  private selectPage: string = 'pages/Index';
  // 缓存 WindowStage，供 onNewWant 复用
  private currentWindowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'Ability onCreate');
    // 解析卡片 router 事件传递的目标页面
    this.parseTargetPage(want);
  }

  // 应用已在后台运行时，卡片点击会触发 onNewWant
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'Ability onNewWant');
    this.parseTargetPage(want);
    if (this.currentWindowStage !== null) {
      this.currentWindowStage.loadContent(this.selectPage, (err) => {
        if (err.code) {
          hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err) ?? '');
        }
      });
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.currentWindowStage = windowStage;
    windowStage.loadContent(this.selectPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN_NUMBER, TAG, 'Failed to load content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in loading content');
    });
  }

  // 解析 want.parameters.params 中的 targetPage（postCardAction 传入的 JSON 字符串）
  private parseTargetPage(want: Want): void {
    try {
      const paramsStr = want?.parameters?.params;
      if (paramsStr) {
        const params: Record<string, Object> = JSON.parse(paramsStr as string) as Record<string, Object>;
        const target = params['targetPage'];
        if (target !== undefined) {
          this.selectPage = 'pages/' + (target as string);
        }
      }
    } catch (e) {
      // 解析失败时回退到主页
      this.selectPage = 'pages/Index';
    }
  }
}
