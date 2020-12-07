package io.rackshift.mybatis.domain;

import lombok.Data;

import java.io.Serializable;

@Data
public class User implements Serializable {
    private String id;

    private String name;

    private String email;

    private String password;

    private String status;

    private Long createTime;

    private Long updateTime;

    private String language;

    private String lastWorkspaceId;

    private String lastOrganizationId;

    private String phone;

    private static final long serialVersionUID = 1L;
}