package com.kindledger.gateway.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "fabric")
public class FabricConfig {
    
    private String networkConfigPath;
    private String channelName;
    private String chaincodeName;
    private String organization;
    private String user;
    
    public String getNetworkConfigPath() {
        return networkConfigPath;
    }
    
    public void setNetworkConfigPath(String networkConfigPath) {
        this.networkConfigPath = networkConfigPath;
    }
    
    public String getChannelName() {
        return channelName;
    }
    
    public void setChannelName(String channelName) {
        this.channelName = channelName;
    }
    
    public String getChaincodeName() {
        return chaincodeName;
    }
    
    public void setChaincodeName(String chaincodeName) {
        this.chaincodeName = chaincodeName;
    }
    
    public String getOrganization() {
        return organization;
    }
    
    public void setOrganization(String organization) {
        this.organization = organization;
    }
    
    public String getUser() {
        return user;
    }
    
    public void setUser(String user) {
        this.user = user;
    }
}
