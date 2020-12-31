package io.rackshift.mybatis.mapper;

import io.rackshift.mybatis.domain.Plugin;
import io.rackshift.mybatis.domain.PluginExample;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface PluginMapper {
    long countByExample(PluginExample example);

    int deleteByExample(PluginExample example);

    int deleteByPrimaryKey(String id);

    int insert(Plugin record);

    int insertSelective(Plugin record);

    List<Plugin> selectByExample(PluginExample example);

    Plugin selectByPrimaryKey(String id);

    int updateByExampleSelective(@Param("record") Plugin record, @Param("example") PluginExample example);

    int updateByExample(@Param("record") Plugin record, @Param("example") PluginExample example);

    int updateByPrimaryKeySelective(Plugin record);

    int updateByPrimaryKey(Plugin record);
}