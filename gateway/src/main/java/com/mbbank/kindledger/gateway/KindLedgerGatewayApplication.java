package com.mbbank.kindledger.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class KindLedgerGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(KindLedgerGatewayApplication.class, args);
    }
}
