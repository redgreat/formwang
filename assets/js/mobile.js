// 移动端适配和微信兼容性处理

// 检测设备类型
const isMobile = () => {
  return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
};

// 检测微信浏览器
const isWeChat = () => {
  return /MicroMessenger/i.test(navigator.userAgent);
};

// 检测iOS设备
const isIOS = () => {
  return /iPad|iPhone|iPod/.test(navigator.userAgent);
};

// 初始化移动端适配
const initMobileAdaptation = () => {
  // 添加设备类型class
  if (isMobile()) {
    document.body.classList.add('mobile-device');
  }
  
  if (isWeChat()) {
    document.body.classList.add('wechat-browser');
  }
  
  if (isIOS()) {
    document.body.classList.add('ios-device');
  }
  
  // 设置viewport
  setViewport();
  
  // 处理iOS输入框焦点问题
  handleIOSInputFocus();
  
  // 处理微信浏览器特殊问题
  handleWeChatIssues();
  
  // 优化触摸体验
  optimizeTouchExperience();
};

// 设置viewport
const setViewport = () => {
  let viewport = document.querySelector('meta[name="viewport"]');
  if (!viewport) {
    viewport = document.createElement('meta');
    viewport.name = 'viewport';
    document.head.appendChild(viewport);
  }
  
  // 防止用户缩放，优化移动端体验
  viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
};

// 处理iOS输入框焦点问题
const handleIOSInputFocus = () => {
  if (!isIOS()) return;
  
  // 监听输入框焦点事件
  document.addEventListener('focusin', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
      // 延迟滚动到输入框位置
      setTimeout(() => {
        e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }, 300);
    }
  });
  
  // 监听输入框失焦事件
  document.addEventListener('focusout', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
      // 恢复页面滚动位置
      setTimeout(() => {
        window.scrollTo(0, 0);
      }, 100);
    }
  });
};

// 处理微信浏览器特殊问题
const handleWeChatIssues = () => {
  if (!isWeChat()) return;
  
  // 禁用微信浏览器的下拉刷新
  document.addEventListener('touchmove', (e) => {
    if (e.touches.length > 1) {
      e.preventDefault();
    }
  }, { passive: false });
  
  // 处理微信浏览器的返回按钮
  window.addEventListener('popstate', (e) => {
    // 可以在这里处理返回逻辑
    console.log('微信浏览器返回事件');
  });
  
  // 微信分享配置（如果需要）
  if (typeof wx !== 'undefined') {
    configWeChatShare();
  }
};

// 配置微信分享
const configWeChatShare = () => {
  // 这里需要后端提供微信JS-SDK配置
  wx.config({
    debug: false,
    appId: '', // 需要从后端获取
    timestamp: '', // 需要从后端获取
    nonceStr: '', // 需要从后端获取
    signature: '', // 需要从后端获取
    jsApiList: ['onMenuShareTimeline', 'onMenuShareAppMessage']
  });
  
  wx.ready(() => {
    // 分享到朋友圈
    wx.onMenuShareTimeline({
      title: document.title,
      link: window.location.href,
      imgUrl: '', // 分享图标
      success: () => {
        console.log('分享到朋友圈成功');
      }
    });
    
    // 分享给朋友
    wx.onMenuShareAppMessage({
      title: document.title,
      desc: '请填写这个表单',
      link: window.location.href,
      imgUrl: '', // 分享图标
      success: () => {
        console.log('分享给朋友成功');
      }
    });
  });
};

// 优化触摸体验
const optimizeTouchExperience = () => {
  // 添加触摸反馈
  document.addEventListener('touchstart', (e) => {
    if (e.target.classList.contains('btn') || e.target.classList.contains('touch-feedback')) {
      e.target.style.opacity = '0.7';
    }
  });
  
  document.addEventListener('touchend', (e) => {
    if (e.target.classList.contains('btn') || e.target.classList.contains('touch-feedback')) {
      setTimeout(() => {
        e.target.style.opacity = '1';
      }, 150);
    }
  });
  
  // 防止双击缩放
  let lastTouchEnd = 0;
  document.addEventListener('touchend', (e) => {
    const now = new Date().getTime();
    if (now - lastTouchEnd <= 300) {
      e.preventDefault();
    }
    lastTouchEnd = now;
  }, false);
};

// 表单提交优化
const optimizeFormSubmission = () => {
  const forms = document.querySelectorAll('form');
  
  forms.forEach(form => {
    form.addEventListener('submit', (e) => {
      const submitBtn = form.querySelector('button[type="submit"], input[type="submit"]');
      
      if (submitBtn) {
        // 防止重复提交
        submitBtn.disabled = true;
        submitBtn.classList.add('loading');
        
        // 显示加载状态
        const originalText = submitBtn.textContent;
        submitBtn.textContent = '提交中...';
        
        // 如果提交失败，恢复按钮状态
        setTimeout(() => {
          if (submitBtn.disabled) {
            submitBtn.disabled = false;
            submitBtn.classList.remove('loading');
            submitBtn.textContent = originalText;
          }
        }, 10000); // 10秒后自动恢复
      }
    });
  });
};

// 文件上传优化
const optimizeFileUpload = () => {
  const fileInputs = document.querySelectorAll('input[type="file"]');
  
  fileInputs.forEach(input => {
    // 创建自定义文件上传界面
    const wrapper = document.createElement('div');
    wrapper.className = 'file-upload-mobile';
    wrapper.innerHTML = `
      <div class="file-upload-icon">
        <svg class="w-8 h-8 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"></path>
        </svg>
      </div>
      <div class="file-upload-text">
        <p class="text-sm text-gray-600">点击选择文件</p>
        <p class="text-xs text-gray-400">支持图片、文档等格式</p>
      </div>
    `;
    
    // 插入到文件输入框前面
    input.parentNode.insertBefore(wrapper, input);
    
    // 点击事件
    wrapper.addEventListener('click', () => {
      input.click();
    });
    
    // 文件选择事件
    input.addEventListener('change', (e) => {
      const files = e.target.files;
      if (files.length > 0) {
        const fileName = files[0].name;
        wrapper.querySelector('.file-upload-text p').textContent = `已选择: ${fileName}`;
        wrapper.style.borderColor = '#3b82f6';
        wrapper.style.backgroundColor = '#eff6ff';
      }
    });
  });
};

// 复制到剪贴板功能
const copyToClipboard = (text) => {
  if (navigator.clipboard) {
    return navigator.clipboard.writeText(text);
  } else {
    // 兼容旧浏览器
    const textArea = document.createElement('textarea');
    textArea.value = text;
    document.body.appendChild(textArea);
    textArea.select();
    document.execCommand('copy');
    document.body.removeChild(textArea);
    return Promise.resolve();
  }
};

// 显示提示消息
const showToast = (message, type = 'info', duration = 3000) => {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
    color: white;
    padding: 12px 24px;
    border-radius: 6px;
    z-index: 9999;
    font-size: 14px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    animation: slideDown 0.3s ease-out;
  `;
  toast.textContent = message;
  
  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.style.animation = 'slideUp 0.3s ease-out';
    setTimeout(() => {
      document.body.removeChild(toast);
    }, 300);
  }, duration);
};

// 添加CSS动画
const addToastAnimations = () => {
  if (!document.querySelector('#toast-animations')) {
    const style = document.createElement('style');
    style.id = 'toast-animations';
    style.textContent = `
      @keyframes slideDown {
        from {
          opacity: 0;
          transform: translateX(-50%) translateY(-20px);
        }
        to {
          opacity: 1;
          transform: translateX(-50%) translateY(0);
        }
      }
      
      @keyframes slideUp {
        from {
          opacity: 1;
          transform: translateX(-50%) translateY(0);
        }
        to {
          opacity: 0;
          transform: translateX(-50%) translateY(-20px);
        }
      }
    `;
    document.head.appendChild(style);
  }
};

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', () => {
  initMobileAdaptation();
  optimizeFormSubmission();
  optimizeFileUpload();
  addToastAnimations();
  
  // 为复制按钮添加事件监听
  document.addEventListener('click', (e) => {
    if (e.target.matches('[data-copy]')) {
      const text = e.target.getAttribute('data-copy');
      copyToClipboard(text).then(() => {
        showToast('已复制到剪贴板', 'success');
      }).catch(() => {
        showToast('复制失败', 'error');
      });
    }
  });
});

// 导出函数供其他脚本使用
window.MobileUtils = {
  isMobile,
  isWeChat,
  isIOS,
  copyToClipboard,
  showToast
};