// common/WidgetConfig.ets
// 服务卡片配置的持久化与数据构建工具
// 说明：卡片背景图与配置统一保存在应用沙箱 filesDir 下，卡片通过 FormBindingData 获取。
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { formBindingData } from '@kit.FormKit';

// 卡片配置数据（字段与卡片页面 @LocalStorageProp 一一对应）
export class WidgetConfigData {
  text: string = '';             // 文字内容
  textPosX: number = 0.5;        // 文字左上角锚点 X（0~1 归一化）
  textPosY: number = 0.5;        // 文字左上角锚点 Y（0~1 归一化）
  textColor: string = '#FFFFFF'; // 文字颜色
  textSize: number = 24;         // 文字字号（fp）
  hasImage: boolean = false;     // 是否已设置背景图
}

// 传给卡片的表单数据包装：data + 需释放的文件句柄
export class FormDataPack {
  data: formBindingData.FormBindingData;
  files: fileIo.File[];

  constructor(data: formBindingData.FormBindingData, files: fileIo.File[]) {
    this.data = data;
    this.files = files;
  }
}

// 传给卡片的数据对象（字段名即 LocalStorage 键）
class FormDataObj {
  text: string = '';
  textPosX: number = 0.5;
  textPosY: number = 0.5;
  textColor: string = '#FFFFFF';
  textSize: number = 24;
  hasImage: boolean = false;
  imgName: string = '';
  formImages: Record<string, number> = {};
}

const CONFIG_FILE: string = 'widget_config.json';
const BG_FILE: string = 'widget_bg.png';
const FORM_IDS_FILE: string = 'form_ids.json';

export class WidgetStore {
  // —— 配置读写 ——
  // 读取卡片配置（文件不存在或解析失败时返回默认值）
  static readConfig(context: common.Context): WidgetConfigData {
    const cfg = new WidgetConfigData();
    try {
      const text = fileIo.readTextSync(context.filesDir + '/' + CONFIG_FILE);
      const obj: Record<string, Object> = JSON.parse(text) as Record<string, Object>;
      if (obj.text !== undefined) {
        cfg.text = obj.text as string;
      }
      if (obj.textPosX !== undefined) {
        cfg.textPosX = obj.textPosX as number;
      }
      if (obj.textPosY !== undefined) {
        cfg.textPosY = obj.textPosY as number;
      }
      if (obj.textColor !== undefined) {
        cfg.textColor = obj.textColor as string;
      }
      if (obj.textSize !== undefined) {
        cfg.textSize = obj.textSize as number;
      }
      if (obj.hasImage !== undefined) {
        cfg.hasImage = obj.hasImage as boolean;
      }
    } catch (e) {
      // 文件不存在或内容非法，返回默认值
    }
    return cfg;
  }

  // 写入文本文件（API 26 移除了 writeTextSync，改用 openSync + writeSync）
  private static writeTextFile(path: string, content: string): void {
    const f = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(f.fd, content);
    fileIo.closeSync(f);
  }

  // 写入卡片配置
  static writeConfig(context: common.Context, cfg: WidgetConfigData): void {
    try {
      WidgetStore.writeTextFile(context.filesDir + '/' + CONFIG_FILE, JSON.stringify(cfg));
    } catch (e) {
      // 忽略写入失败
    }
  }

  // —— formId 追踪 ——
  // 读取已添加的卡片 formId 列表
  static readFormIds(context: common.Context): string[] {
    try {
      const text = fileIo.readTextSync(context.filesDir + '/' + FORM_IDS_FILE);
      return JSON.parse(text) as string[];
    } catch (e) {
      return [];
    }
  }

  // 记录一个 formId（去重）
  static addFormId(context: common.Context, formId: string): void {
    const ids = WidgetStore.readFormIds(context);
    if (ids.indexOf(formId) === -1) {
      ids.push(formId);
      try {
        WidgetStore.writeTextFile(context.filesDir + '/' + FORM_IDS_FILE, JSON.stringify(ids));
      } catch (e) {
      }
    }
  }

  // 移除一个 formId
  static removeFormId(context: common.Context, formId: string): void {
    const ids = WidgetStore.readFormIds(context);
    const idx = ids.indexOf(formId);
    if (idx !== -1) {
      ids.splice(idx, 1);
      try {
        WidgetStore.writeTextFile(context.filesDir + '/' + FORM_IDS_FILE, JSON.stringify(ids));
      } catch (e) {
      }
    }
  }

  // —— 背景图 ——
  // 获取背景图在沙箱中的路径
  static getBgPath(context: common.Context): string {
    return context.filesDir + '/' + BG_FILE;
  }

  // 将用户选择的图片（picker 返回的 URI）拷贝到沙箱
  static copyBgImage(context: common.Context, srcUri: string): boolean {
    const destPath = WidgetStore.getBgPath(context);
    try {
      // 先删除旧背景图
      try {
        fileIo.unlinkSync(destPath);
      } catch (e) {
      }
      // 打开源文件（fileIo 支持 file:// URI）
      const src = fileIo.openSync(srcUri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(src.fd);
      const buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(src.fd, buffer);
      fileIo.closeSync(src);
      // 写入沙箱
      const dest = fileIo.openSync(destPath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(dest.fd, buffer);
      fileIo.closeSync(dest);
      return true;
    } catch (e) {
      return false;
    }
  }

  // 构建传给卡片的表单数据（含背景图 fd）
  // 注意：返回的 files 需要在调用方用完 data 后逐一 close；onAddForm 场景例外（系统接管 fd 生命周期）。
  static buildFormData(context: common.Context): FormDataPack {
    const cfg = WidgetStore.readConfig(context);
    const files: fileIo.File[] = [];
    // 每次刷新必须使用不同的 imgName，否则图片不会刷新
    const imgName = 'bg_' + Date.now().toString() + '_' + Math.floor(Math.random() * 1000000).toString();
    const imgMap: Record<string, number> = {};
    let hasImg = false;
    if (cfg.hasImage) {
      try {
        const f = fileIo.openSync(WidgetStore.getBgPath(context), fileIo.OpenMode.READ_ONLY);
        imgMap[imgName] = f.fd;
        files.push(f);
        hasImg = true;
      } catch (e) {
        hasImg = false;
      }
    }
    const obj = new FormDataObj();
    obj.text = cfg.text;
    obj.textPosX = cfg.textPosX;
    obj.textPosY = cfg.textPosY;
    obj.textColor = cfg.textColor;
    obj.textSize = cfg.textSize;
    obj.hasImage = hasImg;
    obj.imgName = imgName;
    obj.formImages = imgMap;
    return new FormDataPack(formBindingData.createFormBindingData(obj), files);
  }
}
