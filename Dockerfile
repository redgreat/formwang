# 使用官方Elixir镜像作为基础镜像
FROM elixir:1.17.3-alpine AS build

# 安装构建依赖
RUN apk add --no-cache build-base npm git python3

# 设置工作目录
WORKDIR /app

# 安装hex和rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# 复制mix文件
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mkdir config

# 复制配置文件
COPY config/config.exs config/prod.exs config/runtime.exs config/
RUN mix deps.compile

# 复制前端资源
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# 复制应用代码
COPY priv priv
COPY lib lib
COPY assets assets
RUN mix assets.deploy

# 编译发布版本
COPY config/prod.exs config/
RUN mix phx.gen.release
RUN mix release

# 运行时镜像
FROM alpine:3.18 AS app
RUN apk add --no-cache openssl ncurses-libs postgresql-client

WORKDIR /app
RUN chown nobody:nobody /app
USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/formwang ./

CMD ["bin/formwang", "start"]