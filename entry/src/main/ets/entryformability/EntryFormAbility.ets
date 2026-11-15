// entryformability/EntryFormAbility.ets
// 服务卡片（Form Extension）生命周期管理
// 说明：卡片被添加时记录 formId，供主页「应用到卡片」主动刷新使用。
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { WidgetStore } from '../common/WidgetConfig';

export default class EntryFormAbility extends FormExtensionAbility {
  // 卡片被添加到桌面时回调（同步返回数据，不能 await）
  onAddForm(want: Want): formBindingData.FormBindingData {
    // 从 want.parameters 中取出 formId 并持久化
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
    if (formId) {
      WidgetStore.addFormId(this.context, formId);
    }
    // 构建卡片数据（fd 由系统在进程销毁时释放，这里不 close）
    const pack = WidgetStore.buildFormData(this.context);
    return pack.data;
  }

  // 卡片定时更新回调（本应用已关闭定时刷新 updateEnabled=false，一般不会触发）
  onUpdateForm(formId: string): void {
    // 无操作
  }

  // 卡片被移除时回调
  onRemoveForm(formId: string): void {
    WidgetStore.removeFormId(this.context, formId);
  }

  // 卡片事件回调（message 事件，本应用未使用）
  onFormEvent(formId: string, message: string): void {
    // 无操作
  }

  // 卡片可见性变化回调
  onChangeFormVisibility(newStatus: Record<string, number>): void {
    // 无操作
  }

  // 获取卡片状态：返回 READY 表示卡片可用
  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
