package dev258.mini.license_server.common.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
// licensing ou common/config: ficheiro novo SpaController.java
@Controller
public class SpaController {
    @GetMapping({"/login", "/licencas", "/auditoria", "/perfil"})
    public String spa() {
        return "forward:/index.html";
    }
}
