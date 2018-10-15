package io.medgelabs.ebtest;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class IndexController {

    @GetMapping("/")
    public ZimQuote index() {
        return new ZimQuote("I HAVE SING THE DOOM SONG NOW!");
    }

}
