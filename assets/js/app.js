// 引入Phoenix框架的JavaScript
import "phoenix_html";

// 建立WebSocket连接
import {Socket} from "phoenix";
import {LiveSocket} from "phoenix_live_view";
import topbar from "../vendor/topbar";

// 引入移动端适配脚本
import "./mobile.js";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}});

// 显示进度条
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"});
window.addEventListener("phx:page-loading-start", info => topbar.show());
window.addEventListener("phx:page-loading-stop", info => topbar.hide());

// 连接LiveSocket
liveSocket.connect();

// 暴露liveSocket供调试使用（仅开发环境）
window.liveSocket = liveSocket;

// 表单相关功能
class FormHandler {
  constructor() {
    this.init();
  }
  
  init() {
    this.handleFormSubmission();
    this.handleFieldValidation();
    this.handleDynamicFields();
  }
  
  // 处理表单提交
  handleFormSubmission() {
    document.addEventListener('submit', (e) => {
      const form = e.target;
      if (form.classList.contains('public-form')) {
        this.handlePublicFormSubmit(e);
      }
    });
  }
  
  // 处理公共表单提交
  handlePublicFormSubmit(e) {
    const form = e.target;
    const submitBtn = form.querySelector('button[type="submit"]');
    
    if (submitBtn) {
      submitBtn.disabled = true;
      submitBtn.textContent = '提交中...';
      submitBtn.classList.add('loading');
    }
    
    // 验证必填字段
    const requiredFields = form.querySelectorAll('[required]');
    let hasError = false;
    
    requiredFields.forEach(field => {
      if (!field.value.trim()) {
        this.showFieldError(field, '此字段为必填项');
        hasError = true;
      } else {
        this.clearFieldError(field);
      }
    });
    
    if (hasError) {
      e.preventDefault();
      if (submitBtn) {
        submitBtn.disabled = false;
        submitBtn.textContent = '提交表单';
        submitBtn.classList.remove('loading');
      }
      return;
    }
  }
  
  // 显示字段错误
  showFieldError(field, message) {
    field.classList.add('field-error');
    
    // 移除已存在的错误消息
    const existingError = field.parentNode.querySelector('.error-message');
    if (existingError) {
      existingError.remove();
    }
    
    // 添加新的错误消息
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    field.parentNode.appendChild(errorDiv);
  }
  
  // 清除字段错误
  clearFieldError(field) {
    field.classList.remove('field-error');
    const errorMessage = field.parentNode.querySelector('.error-message');
    if (errorMessage) {
      errorMessage.remove();
    }
  }
  
  // 处理字段验证
  handleFieldValidation() {
    document.addEventListener('blur', (e) => {
      const field = e.target;
      if (field.tagName === 'INPUT' || field.tagName === 'TEXTAREA' || field.tagName === 'SELECT') {
        this.validateField(field);
      }
    }, true);
    
    document.addEventListener('input', (e) => {
      const field = e.target;
      if (field.classList.contains('field-error')) {
        this.validateField(field);
      }
    });
  }
  
  // 验证单个字段
  validateField(field) {
    const value = field.value.trim();
    
    // 必填验证
    if (field.hasAttribute('required') && !value) {
      this.showFieldError(field, '此字段为必填项');
      return false;
    }
    
    // 邮箱验证
    if (field.type === 'email' && value) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(value)) {
        this.showFieldError(field, '请输入有效的邮箱地址');
        return false;
      }
    }
    
    // 电话验证
    if (field.type === 'tel' && value) {
      const phoneRegex = /^[1][3-9]\d{9}$/;
      if (!phoneRegex.test(value)) {
        this.showFieldError(field, '请输入有效的手机号码');
        return false;
      }
    }
    
    // 数字验证
    if (field.type === 'number' && value) {
      const min = field.getAttribute('min');
      const max = field.getAttribute('max');
      const numValue = parseFloat(value);
      
      if (min && numValue < parseFloat(min)) {
        this.showFieldError(field, `数值不能小于 ${min}`);
        return false;
      }
      
      if (max && numValue > parseFloat(max)) {
        this.showFieldError(field, `数值不能大于 ${max}`);
        return false;
      }
    }
    
    this.clearFieldError(field);
    return true;
  }
  
  // 处理动态字段
  handleDynamicFields() {
    // 处理复选框组
    document.addEventListener('change', (e) => {
      if (e.target.type === 'checkbox' && e.target.name.includes('[]')) {
        this.updateCheckboxGroup(e.target);
      }
    });
  }
  
  // 更新复选框组
  updateCheckboxGroup(checkbox) {
    const name = checkbox.name;
    const checkboxes = document.querySelectorAll(`input[name="${name}"]`);
    const checkedValues = [];
    
    checkboxes.forEach(cb => {
      if (cb.checked) {
        checkedValues.push(cb.value);
      }
    });
    
    // 更新隐藏字段或其他逻辑
    console.log('选中的值:', checkedValues);
  }
}

// 分享功能
class ShareHandler {
  constructor() {
    this.init();
  }
  
  init() {
    this.handleCopyButtons();
    this.handleQRCode();
  }
  
  // 处理复制按钮
  handleCopyButtons() {
    document.addEventListener('click', (e) => {
      if (e.target.matches('.copy-btn, [data-copy]')) {
        e.preventDefault();
        const text = e.target.getAttribute('data-copy') || e.target.previousElementSibling.value;
        this.copyToClipboard(text);
      }
    });
  }
  
  // 复制到剪贴板
  async copyToClipboard(text) {
    try {
      if (navigator.clipboard) {
        await navigator.clipboard.writeText(text);
      } else {
        // 兼容旧浏览器
        const textArea = document.createElement('textarea');
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
      }
      
      this.showToast('链接已复制到剪贴板', 'success');
    } catch (err) {
      this.showToast('复制失败，请手动复制', 'error');
    }
  }
  
  // 显示提示消息
  showToast(message, type = 'info') {
    if (window.MobileUtils && window.MobileUtils.showToast) {
      window.MobileUtils.showToast(message, type);
    } else {
      alert(message);
    }
  }
  
  // 处理二维码生成
  handleQRCode() {
    // 如果页面有二维码容器，自动生成二维码
    const qrContainers = document.querySelectorAll('[data-qr-url]');
    qrContainers.forEach(container => {
      const url = container.getAttribute('data-qr-url');
      if (url && typeof QRCode !== 'undefined') {
        new QRCode(container, {
          text: url,
          width: 200,
          height: 200,
          colorDark: '#000000',
          colorLight: '#ffffff'
        });
      }
    });
  }
}

// 初始化应用
document.addEventListener('DOMContentLoaded', () => {
  new FormHandler();
  new ShareHandler();
  
  // 添加全局错误处理
  window.addEventListener('error', (e) => {
    console.error('JavaScript错误:', e.error);
  });
  
  // 添加未处理的Promise拒绝处理
  window.addEventListener('unhandledrejection', (e) => {
    console.error('未处理的Promise拒绝:', e.reason);
  });
});