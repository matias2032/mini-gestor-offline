package dev258.mini.license_server.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/wake-up")
public class WakeUpController {

@GetMapping
public ResponseEntity<String> wakeUp() {
    return ResponseEntity.ok("ok");
}
}