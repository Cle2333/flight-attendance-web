package com.cle2333.flightattendance.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * 把仓库根目录的 index.html / admin.html 当静态文件 serve 出去，
 * 行为对齐旧 Node.js 后端（生产环境用同一个端口同时跑 API + 旧 web 静态资源）。
 */
@Configuration
public class StaticResourceConfig implements WebMvcConfigurer {

    private final Path staticDir;

    public StaticResourceConfig(@Value("${app.static-dir}") String dir) {
        Path p = Paths.get(dir).toAbsolutePath().normalize();
        if (!java.nio.file.Files.isDirectory(p)) {
            // dev 默认 `..` 指向 project root；运行 jar 时它是相对 cwd 的。
            // 如果目录不存在就退化到当前工作目录，避免启动失败
            this.staticDir = Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize();
        } else {
            this.staticDir = p;
        }
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        File f = staticDir.toFile();
        String location = f.toURI().toString();
        if (!location.endsWith("/")) location = location + "/";
        registry.addResourceHandler("/**")
                .addResourceLocations(location)
                .setCachePeriod(0);
    }

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // SPA fallback —— 任何非 /api 路径都返回 index.html
        registry.addViewController("/").setViewName("forward:/index.html");
    }
}
