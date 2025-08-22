defmodule FormwangWeb.FormHTML do
  use FormwangWeb, :html

  embed_templates "form_html/*"

  def share(assigns), do: ~H"""
  <.header>
    分享表单：<%= @form.title %>
    <:subtitle>通过以下方式分享您的表单</:subtitle>
  </.header>

  <div class="space-y-6">
    <!-- 分享链接 -->
    <div class="bg-white p-6 rounded-lg border">
      <h3 class="text-lg font-medium mb-4">分享链接</h3>
      
      <div class="space-y-4">
        <!-- 通过Slug分享 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">公开链接</label>
          <div class="flex">
            <input 
              type="text" 
              value={url(FormwangWeb.Endpoint, ~p"/forms/#{@form.slug}")} 
              readonly 
              class="flex-1 px-3 py-2 border border-gray-300 rounded-l-md bg-gray-50"
            />
            <button 
              onclick={"navigator.clipboard.writeText('#{url(FormwangWeb.Endpoint, ~p"/forms/#{@form.slug}")}')"}
              class="px-4 py-2 bg-blue-600 text-white rounded-r-md hover:bg-blue-700"
            >
              复制
            </button>
          </div>
        </div>
        
        <!-- 通过Token分享 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">私密链接</label>
          <div class="flex">
            <input 
              type="text" 
              value={url(FormwangWeb.Endpoint, ~p"/forms/token/#{@form.share_token}")} 
              readonly 
              class="flex-1 px-3 py-2 border border-gray-300 rounded-l-md bg-gray-50"
            />
            <button 
              onclick={"navigator.clipboard.writeText('#{url(FormwangWeb.Endpoint, ~p"/forms/token/#{@form.share_token}")}')"}
              class="px-4 py-2 bg-blue-600 text-white rounded-r-md hover:bg-blue-700"
            >
              复制
            </button>
          </div>
          <p class="text-sm text-gray-500 mt-1">私密链接可以随时重新生成</p>
        </div>
      </div>
      
      <div class="mt-4">
        <.link 
          href={~p"/admin/forms/#{@form.id}/regenerate_token"} 
          method="post"
          class="text-sm text-blue-600 hover:text-blue-800"
          data-confirm="确定要重新生成私密链接吗？旧链接将失效。"
        >
          重新生成私密链接
        </.link>
      </div>
    </div>
    
    <!-- 二维码 -->
    <div class="bg-white p-6 rounded-lg border">
      <h3 class="text-lg font-medium mb-4">二维码分享</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="text-center">
          <h4 class="font-medium mb-2">公开链接二维码</h4>
          <div id="qr-public" class="mx-auto" style="width: 200px; height: 200px;"></div>
        </div>
        
        <div class="text-center">
          <h4 class="font-medium mb-2">私密链接二维码</h4>
          <div id="qr-private" class="mx-auto" style="width: 200px; height: 200px;"></div>
        </div>
      </div>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/qrcode@1.5.3/build/qrcode.min.js"></script>
  <script>
    // 生成公开链接二维码
    QRCode.toCanvas(document.getElementById('qr-public'), '<%= url(FormwangWeb.Endpoint, ~p"/forms/#{@form.slug}") %>', function (error) {
      if (error) console.error(error)
    })
    
    // 生成私密链接二维码
    QRCode.toCanvas(document.getElementById('qr-private'), '<%= url(FormwangWeb.Endpoint, ~p"/forms/token/#{@form.share_token}") %>', function (error) {
      if (error) console.error(error)
    })
  </script>

  <.back navigate={~p"/admin/forms"}>返回</.back>
  """
end