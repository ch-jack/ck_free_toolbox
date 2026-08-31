function New-CkClothingRepackerPage {
    param([Parameter(Mandatory)]$Context)

    $state = [pscustomobject]@{
        Process = $null
        CancelRequested = $false
        StartedAt = $null
        CommandKey = ''
        CommandName = ''
        Arguments = @()
        Output = New-Object Text.StringBuilder
        LogPath = ''
        ResultPath = ''
        TrustContext = $null
        ApplyBackupRoot = ''
        ExistingManifests = @()
    }

    $xaml = @"
<ScrollViewer xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
              xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
              VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"
              Padding="22,16,28,32">
  <ScrollViewer.Resources>
    <Style TargetType="{x:Type ComboBox}">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#F4F7FB"/>
      <Setter Property="BorderBrush" Value="#596273"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="9,6"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Style.Triggers>
        <Trigger Property="IsKeyboardFocusWithin" Value="True">
          <Setter Property="BorderBrush" Value="#58A6FF"/>
        </Trigger>
        <Trigger Property="IsEnabled" Value="False">
          <Setter Property="Foreground" Value="#4B5563"/>
          <Setter Property="Background" Value="#D7DCE3"/>
          <Setter Property="BorderBrush" Value="#8B95A3"/>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style TargetType="{x:Type ComboBoxItem}">
      <Setter Property="Foreground" Value="#F4F7FB"/>
      <Setter Property="Background" Value="#20242B"/>
      <Setter Property="BorderBrush" Value="#343A46"/>
      <Setter Property="BorderThickness" Value="0,0,0,1"/>
      <Setter Property="Padding" Value="10,8"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="OverridesDefaultStyle" Value="True"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="{x:Type ComboBoxItem}">
            <Border x:Name="ItemBorder"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    Padding="{TemplateBinding Padding}"
                    SnapsToDevicePixels="True">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}"
                                VerticalAlignment="{TemplateBinding VerticalContentAlignment}"
                                SnapsToDevicePixels="{TemplateBinding SnapsToDevicePixels}"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True">
                <Setter TargetName="ItemBorder" Property="Background" Value="#315A91"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="ItemBorder" Property="Background" Value="#173055"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="ItemBorder" Property="Background" Value="#191C21"/>
                <Setter TargetName="ItemBorder" Property="BorderBrush" Value="#2A2E37"/>
                <Setter Property="Foreground" Value="#8F98A5"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </ScrollViewer.Resources>
  <StackPanel>
    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,12">
          <StackPanel Orientation="Horizontal">
            <Border Width="4" Height="22" CornerRadius="3" Background="#E58A4E" Margin="0,0,10,0"/>
            <StackPanel>
              <TextBlock Text="衣服资源打包" FontSize="21" FontWeight="Bold"/>
              <TextBlock Text="Red40 Clothing Repacker CLI · 分析、生成、应用、恢复、校验、报告与 YMT XML 导出" Foreground="#AAB2BE" FontSize="12" Margin="0,4,0,0"/>
            </StackPanel>
          </StackPanel>
          <TextBlock x:Name="EnvironmentStatus" Text="检测中" HorizontalAlignment="Right" VerticalAlignment="Center" Foreground="#F4B860" FontSize="14" FontWeight="SemiBold"/>
        </Grid>
        <Border Background="#16181B" BorderBrush="#242833" BorderThickness="1" CornerRadius="6" Padding="11">
          <Grid>
            <Grid.ColumnDefinitions><ColumnDefinition Width="18"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Ellipse x:Name="ComponentDot" Width="9" Height="9" Fill="#F4B860" VerticalAlignment="Center"/>
            <StackPanel Grid.Column="1">
              <TextBlock Text="Red40 CLI 组件" FontSize="14" FontWeight="SemiBold"/>
              <TextBlock x:Name="ComponentText" Text="检测中" Foreground="#AAB2BE" FontSize="11" TextTrimming="CharacterEllipsis"/>
            </StackPanel>
          </Grid>
        </Border>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="选择 CLI 功能" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="250"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <ComboBox x:Name="CommandBox" Height="36" SelectedIndex="0" AutomationProperties.AutomationId="ClothingRepacker.CommandBox">
            <ComboBoxItem Content="分析打包方案" Tag="analyze"/>
            <ComboBoxItem Content="生成合并资源" Tag="build"/>
            <ComboBoxItem Content="应用方案到资源" Tag="apply"/>
            <ComboBoxItem Content="恢复已应用修改" Tag="restore"/>
            <ComboBoxItem Content="校验方案文件" Tag="validate-plan"/>
            <ComboBoxItem Content="校验资源父目录" Tag="validate-parent"/>
            <ComboBoxItem Content="校验指定资源列表" Tag="validate-list"/>
            <ComboBoxItem Content="生成打包报告" Tag="report"/>
            <ComboBoxItem Content="导出 YMT XML" Tag="export-xml"/>
          </ComboBox>
          <TextBlock x:Name="CommandDescription" Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center" Foreground="#C4CBD5" FontSize="12" TextWrapping="Wrap"/>
        </Grid>
        <CheckBox x:Name="NoVersionCheckCheck" Content="跳过 CLI 自带在线版本检查（推荐；组件更新由工具箱负责）" IsChecked="True" Foreground="#8FC7F3" Margin="0,12,0,0"/>
      </StackPanel>
    </Border>

    <Border x:Name="AnalyzePanel" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <TextBlock Text="分析参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="210"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="资源选择方式" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><ComboBox x:Name="AnalyzeInputModeBox" Height="36" SelectedIndex="0"><ComboBoxItem Content="扫描父目录下的 resources" Tag="parent"/><ComboBoxItem Content="逐个指定 resource 目录" Tag="list"/></ComboBox></StackPanel>
          <TextBlock Grid.Column="1" Text="父目录模式适合标准 resources 目录；指定列表模式可跨目录选择，并需要填写生成资源的父目录。" Margin="14,22,0,0" Foreground="#AAB2BE" FontSize="12" TextWrapping="Wrap"/>
        </Grid>
        <Grid x:Name="AnalyzeParentGrid" Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="资源父目录" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="AnalyzeParentBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseAnalyzeParentButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/>
        </Grid>
        <Grid x:Name="AnalyzeListGrid" Visibility="Collapsed" Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <StackPanel>
            <TextBlock Text="指定 resource 目录（每行一个）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/>
            <TextBox x:Name="AnalyzeResourcesBox" MinHeight="76" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/>
            <Grid Margin="0,8,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="生成资源父目录（--generated-root）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="AnalyzeGeneratedRootBox" Height="36"/></StackPanel><Button x:Name="ChooseAnalyzeGeneratedRootButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid>
          </StackPanel>
          <StackPanel Grid.Column="1" Margin="8,22,0,0"><Button x:Name="AddAnalyzeResourceButton" Content="添加目录" Height="34"/><Button x:Name="ClearAnalyzeResourcesButton" Content="清空列表" Height="34" Margin="0,8,0,0"/></StackPanel>
        </Grid>
        <Grid Margin="0,0,0,10">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
          <StackPanel><TextBlock Text="方案文件（plan.json）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="AnalyzePlanBox" Height="36"/></StackPanel>
          <Button x:Name="ChooseAnalyzePlanButton" Grid.Column="1" Content="保存位置" Height="36" Margin="8,22,0,0"/>
        </Grid>
        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><StackPanel Margin="0,0,5,0"><TextBlock Text="目标 resource 名称" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="TargetResourceBox" Height="36" Text="zz_merged_clothing_meta"/></StackPanel><StackPanel Grid.Column="1" Margin="5,0,0,0"><TextBlock Text="集合前缀" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="TargetPrefixBox" Height="36" Text="merged"/></StackPanel></Grid>
        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><StackPanel Margin="0,0,5,0"><TextBlock Text="女性集合前缀（留空则自动生成）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="FemalePrefixBox" Height="36"/></StackPanel><StackPanel Grid.Column="1" Margin="5,0,0,0"><TextBlock Text="男性集合前缀（留空则自动生成）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="MalePrefixBox" Height="36"/></StackPanel></Grid>
        <Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions><StackPanel Margin="0,0,5,0"><TextBlock Text="每个组件最大 drawable 数" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="MaxComponentBox" Height="36" Text="256"/></StackPanel><StackPanel Grid.Column="1" Margin="5,0,0,0"><TextBlock Text="每个 prop 最大 drawable 数" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="MaxPropBox" Height="36" Text="256"/></StackPanel></Grid>
        <CheckBox x:Name="OptimizeCheck" Content="优化 YMT 使用量（允许把同一来源的组件/prop 分配到不同目标集合）" Foreground="#D7C38D"/>
      </StackPanel>
    </Border>

    <Border x:Name="BuildPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel><TextBlock Text="生成参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="方案文件" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="BuildPlanBox" Height="36"/></StackPanel><Button x:Name="ChooseBuildPlanButton" Grid.Column="1" Content="选择文件" Height="36" Margin="8,22,0,0"/></Grid><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="预览输出目录" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="BuildOutputBox" Height="36"/></StackPanel><Button x:Name="ChooseBuildOutputButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid><StackPanel Orientation="Horizontal"><CheckBox x:Name="BuildXmlCheck" Content="包含 YMT XML 预览" IsChecked="True" Foreground="#B8C0CC"/><CheckBox x:Name="BuildDebugCheck" Content="包含客户端校验脚本" IsChecked="True" Foreground="#B8C0CC" Margin="26,0,0,0"/></StackPanel></StackPanel>
    </Border>

    <Border x:Name="ApplyPanel" Visibility="Collapsed" Background="#15110E" BorderBrush="#5D3A24" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel><TextBlock Text="应用参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,4"/><TextBlock Text="应用会重命名 stream 文件、备份并移除源 YMT，再生成合并 resource。建议保持“复制后处理”。" Foreground="#F4B860" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,12"/><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="方案文件" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ApplyPlanBox" Height="36"/></StackPanel><Button x:Name="ChooseApplyPlanButton" Grid.Column="1" Content="选择文件" Height="36" Margin="8,22,0,0"/></Grid><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="备份根目录（每次自动建立独立子目录）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ApplyBackupBox" Height="36"/></StackPanel><Button x:Name="ChooseApplyBackupButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid><CheckBox x:Name="CopyResourcesCheck" Content="先复制资源到方案输出目录，再对副本改名（推荐）" IsChecked="True" Foreground="#54E0A9" Margin="0,0,0,8"/><StackPanel Orientation="Horizontal"><CheckBox x:Name="ApplyXmlCheck" Content="包含 YMT XML 预览" IsChecked="True" Foreground="#B8C0CC"/><CheckBox x:Name="ApplyDebugCheck" Content="包含客户端校验脚本" IsChecked="True" Foreground="#B8C0CC" Margin="26,0,0,0"/></StackPanel></StackPanel>
    </Border>

    <Border x:Name="RestorePanel" Visibility="Collapsed" Background="#15110E" BorderBrush="#5D3A24" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="恢复参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,4"/><TextBlock Text="恢复会删除该次 apply 生成的合并资源，并按清单还原 YMT 与 stream 文件名。请保留完整时间戳备份目录。" Foreground="#F4B860" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,12"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="backup-manifest.json" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="RestoreManifestBox" Height="36"/></StackPanel><Button x:Name="ChooseRestoreManifestButton" Grid.Column="1" Content="选择文件" Height="36" Margin="8,22,0,0"/></Grid></StackPanel></Border>

    <Border x:Name="ValidatePlanPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="校验方案" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="方案文件" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ValidatePlanBox" Height="36"/></StackPanel><Button x:Name="ChooseValidatePlanButton" Grid.Column="1" Content="选择文件" Height="36" Margin="8,22,0,0"/></Grid></StackPanel></Border>

    <Border x:Name="ValidateParentPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="校验资源父目录" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="资源父目录" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ValidateParentBox" Height="36"/></StackPanel><Button x:Name="ChooseValidateParentButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid></StackPanel></Border>

    <Border x:Name="ValidateListPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="校验指定资源" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="指定 resource 目录（每行一个）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ValidateResourcesBox" MinHeight="76" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/></StackPanel><StackPanel Grid.Column="1" Margin="8,22,0,0"><Button x:Name="AddValidateResourceButton" Content="添加目录" Height="34"/><Button x:Name="ClearValidateResourcesButton" Content="清空列表" Height="34" Margin="0,8,0,0"/></StackPanel></Grid><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="生成资源父目录（--generated-root）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ValidateGeneratedRootBox" Height="36"/></StackPanel><Button x:Name="ChooseValidateGeneratedRootButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid></StackPanel></Border>

    <Border x:Name="ReportPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="报告参数" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="方案文件" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ReportPlanBox" Height="36"/></StackPanel><Button x:Name="ChooseReportPlanButton" Grid.Column="1" Content="选择文件" Height="36" Margin="8,22,0,0"/></Grid><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="报告文件（可留空，仅输出到日志）" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ReportOutputBox" Height="36"/></StackPanel><Button x:Name="ChooseReportOutputButton" Grid.Column="1" Content="保存位置" Height="36" Margin="8,22,0,0"/><Button x:Name="ClearReportOutputButton" Grid.Column="2" Content="仅看日志" Height="36" Margin="8,22,0,0"/></Grid></StackPanel></Border>

    <Border x:Name="ExportPanel" Visibility="Collapsed" Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14"><StackPanel><TextBlock Text="YMT XML 导出" FontSize="18" FontWeight="Bold" Margin="0,0,0,12"/><Grid Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="包含 .ymt 的目录" Foreground="#C4CBD5" FontSize="12" Margin="0,0,0,5"/><TextBox x:Name="ExportFolderBox" Height="36"/></StackPanel><Button x:Name="ChooseExportFolderButton" Grid.Column="1" Content="选择目录" Height="36" Margin="8,22,0,0"/></Grid><CheckBox x:Name="ExportOverwriteCheck" Content="覆盖已经存在的同名 .ymt.xml" Foreground="#F4B860"/></StackPanel></Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,14">
      <StackPanel>
        <Grid Margin="0,0,0,10"><TextBlock Text="CLI 任务" FontSize="18" FontWeight="Bold"/><TextBlock x:Name="ResultStatus" Text="等待任务" HorizontalAlignment="Right" Foreground="#AAB2BE" FontSize="13" VerticalAlignment="Center"/></Grid>
        <ProgressBar x:Name="ProgressBar" Height="8" Minimum="0" Maximum="100" Value="0"/>
        <TextBlock x:Name="StatusLine" Text="选择功能并填写参数后开始。" Foreground="#C4CBD5" FontSize="13" Margin="0,9,0,12" TextWrapping="Wrap"/>
        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="125"/><ColumnDefinition Width="125"/></Grid.ColumnDefinitions><Button x:Name="StartButton" Content="开始分析" Height="44" Margin="0,0,7,0" Background="#124834" Foreground="#54E0A9" FontSize="15" FontWeight="Bold"/><Button x:Name="StopButton" Grid.Column="1" Content="停止任务" Height="44" Margin="7,0" Foreground="#F28B94" IsEnabled="False"/><Button x:Name="OpenResultButton" Grid.Column="2" Content="打开结果" Height="44" Margin="7,0,0,0" Foreground="#72B7F2" IsEnabled="False"/></Grid>
      </StackPanel>
    </Border>

    <Border Background="#101214" BorderBrush="#242833" BorderThickness="1" CornerRadius="8" Padding="16">
      <StackPanel><Grid Margin="0,0,0,9"><TextBlock Text="任务日志" FontSize="18" FontWeight="Bold"/><Button x:Name="OpenLogButton" Content="打开本次日志" Height="28" HorizontalAlignment="Right" IsEnabled="False"/></Grid><TextBox x:Name="LogBox" AutomationProperties.AutomationId="ClothingRepacker.LogBox" MinHeight="190" MaxHeight="420" AcceptsReturn="True" TextWrapping="NoWrap" HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="12" IsReadOnly="True" Text="等待任务输出..."/></StackPanel>
    </Border>
  </StackPanel>
</ScrollViewer>
"@

    $root = Import-CkXaml $xaml
    $ui = Get-CkNamedControls -Root $root -Names @(
        'EnvironmentStatus','ComponentDot','ComponentText','CommandBox','CommandDescription','NoVersionCheckCheck',
        'AnalyzePanel','AnalyzeInputModeBox','AnalyzeParentGrid','AnalyzeListGrid','AnalyzeParentBox','ChooseAnalyzeParentButton',
        'AnalyzeResourcesBox','AddAnalyzeResourceButton','ClearAnalyzeResourcesButton','AnalyzeGeneratedRootBox','ChooseAnalyzeGeneratedRootButton',
        'AnalyzePlanBox','ChooseAnalyzePlanButton','TargetResourceBox','TargetPrefixBox','FemalePrefixBox','MalePrefixBox','MaxComponentBox','MaxPropBox','OptimizeCheck',
        'BuildPanel','BuildPlanBox','ChooseBuildPlanButton','BuildOutputBox','ChooseBuildOutputButton','BuildXmlCheck','BuildDebugCheck',
        'ApplyPanel','ApplyPlanBox','ChooseApplyPlanButton','ApplyBackupBox','ChooseApplyBackupButton','CopyResourcesCheck','ApplyXmlCheck','ApplyDebugCheck',
        'RestorePanel','RestoreManifestBox','ChooseRestoreManifestButton','ValidatePlanPanel','ValidatePlanBox','ChooseValidatePlanButton',
        'ValidateParentPanel','ValidateParentBox','ChooseValidateParentButton','ValidateListPanel','ValidateResourcesBox','AddValidateResourceButton','ClearValidateResourcesButton','ValidateGeneratedRootBox','ChooseValidateGeneratedRootButton',
        'ReportPanel','ReportPlanBox','ChooseReportPlanButton','ReportOutputBox','ChooseReportOutputButton','ClearReportOutputButton',
        'ExportPanel','ExportFolderBox','ChooseExportFolderButton','ExportOverwriteCheck',
        'ResultStatus','ProgressBar','StatusLine','StartButton','StopButton','OpenResultButton','OpenLogButton','LogBox'
    )

    $workRoot = [string]$Context.Paths.DefaultClothingRepackerWork
    $defaultPlan = Join-Path $workRoot 'plan.json'
    $ui.AnalyzePlanBox.Text = $defaultPlan
    $ui.AnalyzeGeneratedRootBox.Text = Join-Path $workRoot 'generated'
    $ui.BuildPlanBox.Text = $defaultPlan
    $ui.BuildOutputBox.Text = Join-Path $workRoot 'preview'
    $ui.ApplyPlanBox.Text = $defaultPlan
    $ui.ApplyBackupBox.Text = Join-Path $workRoot 'backups'
    $ui.ValidatePlanBox.Text = $defaultPlan
    $ui.ValidateGeneratedRootBox.Text = Join-Path $workRoot 'generated'
    $ui.ReportPlanBox.Text = $defaultPlan
    $ui.ReportOutputBox.Text = Join-Path $workRoot 'repack-report.txt'

    $getCommandKeyAction = {
        $item = $ui.CommandBox.SelectedItem
        if (-not $item) { return 'analyze' }
        return [string]$item.Tag
    }.GetNewClosure()

    $updateEnvironmentAction = {
        $componentOk = Test-Path -LiteralPath $Context.Paths.ClothingRepackerExe -PathType Leaf
        Set-CkStatusDot $ui.ComponentDot $componentOk
        $ui.ComponentText.Text = if ($componentOk) { '自包含 Windows x64 CLI 已就绪' } else { '请在顶部安装组件' }
        $ui.ComponentText.ToolTip = [string]$Context.Paths.ClothingRepackerExe
        $ui.EnvironmentStatus.Text = if ($componentOk) { '运行环境就绪' } else { '组件未安装' }
        $ui.EnvironmentStatus.Foreground = if ($componentOk) { (Get-CkThemeBrush '#31D69A') } else { (Get-CkThemeBrush '#F4B860') }
    }.GetNewClosure()

    $updateAnalyzeInputModeAction = {
        $mode = if ($ui.AnalyzeInputModeBox.SelectedItem) { [string]$ui.AnalyzeInputModeBox.SelectedItem.Tag } else { 'parent' }
        $ui.AnalyzeParentGrid.Visibility = if ($mode -eq 'parent') { 'Visible' } else { 'Collapsed' }
        $ui.AnalyzeListGrid.Visibility = if ($mode -eq 'list') { 'Visible' } else { 'Collapsed' }
    }.GetNewClosure()

    $updateCommandUiAction = {
        $key = & $getCommandKeyAction
        foreach ($panel in @($ui.AnalyzePanel,$ui.BuildPanel,$ui.ApplyPanel,$ui.RestorePanel,$ui.ValidatePlanPanel,$ui.ValidateParentPanel,$ui.ValidateListPanel,$ui.ReportPanel,$ui.ExportPanel)) {
            $panel.Visibility = 'Collapsed'
        }
        $description = ''
        $buttonText = '开始任务'
        switch ($key) {
            'analyze' { $ui.AnalyzePanel.Visibility = 'Visible'; $description = '扫描服装资源并生成可审查的 plan.json，不修改源文件。'; $buttonText = '开始分析' }
            'build' { $ui.BuildPanel.Visibility = 'Visible'; $description = '根据方案生成独立预览 resource，不修改源资源。'; $buttonText = '开始生成' }
            'apply' { $ui.ApplyPanel.Visibility = 'Visible'; $description = '按方案执行文件改名、备份与合并资源生成。'; $buttonText = '应用方案' }
            'restore' { $ui.RestorePanel.Visibility = 'Visible'; $description = '使用 apply 生成的备份清单撤销该次修改。'; $buttonText = '开始恢复' }
            'validate-plan' { $ui.ValidatePlanPanel.Visibility = 'Visible'; $description = '检查 plan.json 的结构与规划错误。'; $buttonText = '校验方案' }
            'validate-parent' { $ui.ValidateParentPanel.Visibility = 'Visible'; $description = '扫描父目录下的资源并报告 YMT 规划错误。'; $buttonText = '校验目录' }
            'validate-list' { $ui.ValidateListPanel.Visibility = 'Visible'; $description = '校验逐个指定的 resource 目录。'; $buttonText = '校验资源' }
            'report' { $ui.ReportPanel.Visibility = 'Visible'; $description = '把方案中的来源与目标 YMT 分配关系输出为文本报告。'; $buttonText = '生成报告' }
            'export-xml' { $ui.ExportPanel.Visibility = 'Visible'; $description = '把目录中的二进制 .ymt 导出为便于检查的 XML。'; $buttonText = '导出 XML' }
        }
        $ui.CommandDescription.Text = $description
        $ui.StartButton.Content = $buttonText
        $ui.StatusLine.Text = '填写当前功能所需参数后开始。'
    }.GetNewClosure()

    $showPageError = {
        param([string]$Message)
        $ui.ResultStatus.Text = '操作失败'
        $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
        $ui.StatusLine.Text = $Message
        Add-CkLogLine -TextBox $ui.LogBox -Line "[工具箱] $Message"
        [System.Windows.MessageBox]::Show($Message, 'CK免费工具箱 - 衣服资源打包') | Out-Null
    }.GetNewClosure()

    $chooseFolderAction = {
        param($TextBox, [string]$Description, [bool]$AllowCreate)
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Description
        $dialog.SelectedPath = $TextBox.Text.Trim()
        $dialog.ShowNewFolderButton = $AllowCreate
        try {
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $TextBox.Text = $dialog.SelectedPath }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $chooseOpenFileAction = {
        param($TextBox, [string]$Filter, [string]$Title)
        $dialog = New-Object Microsoft.Win32.OpenFileDialog
        $dialog.Filter = $Filter
        $dialog.Title = $Title
        $current = $TextBox.Text.Trim()
        if ($current) {
            if (Test-Path -LiteralPath $current -PathType Leaf) { $dialog.FileName = $current }
            elseif (Test-Path -LiteralPath (Split-Path -Parent $current) -PathType Container) { $dialog.InitialDirectory = Split-Path -Parent $current }
        }
        if ($dialog.ShowDialog() -eq $true) { $TextBox.Text = $dialog.FileName }
    }.GetNewClosure()

    $chooseSaveFileAction = {
        param($TextBox, [string]$Filter, [string]$Title, [string]$DefaultExtension)
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = $Filter
        $dialog.Title = $Title
        $dialog.DefaultExt = $DefaultExtension
        $dialog.AddExtension = $true
        $current = $TextBox.Text.Trim()
        if ($current) { $dialog.FileName = $current }
        if ($dialog.ShowDialog() -eq $true) { $TextBox.Text = $dialog.FileName }
    }.GetNewClosure()

    $appendResourceAction = {
        param($TextBox, [string]$Description)
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = $Description
        $dialog.ShowNewFolderButton = $false
        try {
            if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
            $selected = [IO.Path]::GetFullPath($dialog.SelectedPath).TrimEnd('\')
            $current = @([regex]::Split($TextBox.Text, '\r?\n') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            if ($current -notcontains $selected) { $TextBox.Text = (@($current) + $selected) -join [Environment]::NewLine }
        } finally { $dialog.Dispose() }
    }.GetNewClosure()

    $getResourcePathsAction = {
        param([string]$Text)
        $paths = New-Object System.Collections.Generic.List[string]
        foreach ($line in @([regex]::Split($Text, '\r?\n'))) {
            $value = $line.Trim().Trim('"')
            if (-not $value) { continue }
            $full = [IO.Path]::GetFullPath($value).TrimEnd('\')
            if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw "resource 目录不存在: $full" }
            $rootPath = [IO.Path]::GetPathRoot($full).TrimEnd('\')
            if ($full.Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw '不能把整个磁盘作为 resource。' }
            if (-not $paths.Contains($full)) { $paths.Add($full) }
        }
        if ($paths.Count -eq 0) { throw '请至少添加一个 resource 目录。' }
        return $paths.ToArray()
    }.GetNewClosure()

    $getExistingFileAction = {
        param([string]$Value, [string]$Label)
        if (-not $Value.Trim()) { throw "请填写${Label}。" }
        $full = [IO.Path]::GetFullPath($Value.Trim().Trim('"'))
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "${Label}不存在: $full" }
        return $full
    }.GetNewClosure()

    $getExistingDirectoryAction = {
        param([string]$Value, [string]$Label, [bool]$RejectRoot)
        if (-not $Value.Trim()) { throw "请填写${Label}。" }
        $full = [IO.Path]::GetFullPath($Value.Trim().Trim('"')).TrimEnd('\')
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { throw "${Label}不存在: $full" }
        if ($RejectRoot) {
            $rootPath = [IO.Path]::GetPathRoot($full).TrimEnd('\')
            if ($full.Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw "不能把整个磁盘作为${Label}。" }
        }
        return $full
    }.GetNewClosure()

    $getOutputDirectoryAction = {
        param([string]$Value, [string]$Label, [bool]$Create)
        if (-not $Value.Trim()) { throw "请填写${Label}。" }
        $full = [IO.Path]::GetFullPath($Value.Trim().Trim('"')).TrimEnd('\')
        $rootPath = [IO.Path]::GetPathRoot($full).TrimEnd('\')
        if ($full.Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw "不能直接把${Label}设为磁盘根目录。" }
        if ($Create -and -not (Test-Path -LiteralPath $full -PathType Container)) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
        return $full
    }.GetNewClosure()

    $getOutputFileAction = {
        param([string]$Value, [string]$Label)
        if (-not $Value.Trim()) { throw "请填写${Label}。" }
        $full = [IO.Path]::GetFullPath($Value.Trim().Trim('"'))
        $parent = Split-Path -Parent $full
        if (-not $parent) { throw "${Label}缺少父目录。" }
        $rootPath = [IO.Path]::GetPathRoot($parent).TrimEnd('\')
        if ($parent.TrimEnd('\').Equals($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw "${Label}不能直接写到磁盘根目录。" }
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        return $full
    }.GetNewClosure()

    $getPositiveIntAction = {
        param([string]$Value, [string]$Label)
        $parsed = 0
        if (-not [int]::TryParse($Value.Trim(), [ref]$parsed) -or $parsed -le 0) { throw "${Label}必须是正整数。" }
        return $parsed
    }.GetNewClosure()

    $assertResourceNameAction = {
        param([string]$Value, [string]$Label)
        $trimmed = $Value.Trim()
        if (-not $trimmed) { throw "请填写${Label}。" }
        if ($trimmed.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $trimmed -in @('.','..') -or $trimmed -match '[\.\s]$') { throw "${Label}包含无效字符或以点/空格结尾。" }
        if ($trimmed -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') { throw "${Label}不能使用 Windows 设备保留名。" }
        return $trimmed
    }.GetNewClosure()

    $assertGeneratedNameAction = {
        param([string]$Value, [string]$Label)
        $trimmed = & $assertResourceNameAction $Value $Label
        if ($trimmed -notmatch '^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$') { throw "${Label}只能使用英文字母、数字、下划线、点和短横线，并且必须以字母或数字开头。" }
        return $trimmed
    }.GetNewClosure()

    $normalizeLocalPathAction = {
        param([string]$Value, [string]$Label)
        if ([string]::IsNullOrWhiteSpace($Value)) { throw "${Label}为空。" }
        $trimmed = $Value.Trim().Trim('"')
        if ($trimmed.StartsWith('\\') -or $trimmed.StartsWith('//') -or $trimmed.StartsWith('\\?\') -or $trimmed.StartsWith('\\.\')) {
            throw "${Label}不能使用 UNC 或设备路径。"
        }
        return [IO.Path]::GetFullPath($trimmed).TrimEnd('\')
    }.GetNewClosure()

    $isPathAtOrInsideAction = {
        param([string]$Path, [string]$Parent)
        $fullPath = (& $normalizeLocalPathAction $Path '路径')
        $fullParent = (& $normalizeLocalPathAction $Parent '父路径')
        return (
            $fullPath.Equals($fullParent, [StringComparison]::OrdinalIgnoreCase) -or
            $fullPath.StartsWith($fullParent + '\', [StringComparison]::OrdinalIgnoreCase)
        )
    }.GetNewClosure()

    $getContainingRootAction = {
        param([string]$Path, [string[]]$Roots)
        $full = & $normalizeLocalPathAction $Path '方案路径'
        foreach ($rootPath in @($Roots)) {
            if (& $isPathAtOrInsideAction $full $rootPath) { return (& $normalizeLocalPathAction $rootPath 'resource 根目录') }
        }
        return ''
    }.GetNewClosure()

    $assertNoReparseAction = {
        param([string]$Path, [string]$Label)
        $full = & $normalizeLocalPathAction $Path $Label
        $current = $full
        while ($current) {
            if (Test-Path -LiteralPath $current) {
                $item = Get-Item -LiteralPath $current -Force
                if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "${Label}经过重解析点，拒绝执行: $current" }
            }
            $parent = Split-Path -Parent $current
            if (-not $parent -or $parent.Equals($current, [StringComparison]::OrdinalIgnoreCase)) { break }
            $current = $parent
        }
    }.GetNewClosure()

    $assertNoDescendantReparseAction = {
        param([string]$Path, [string]$Label)
        $full = & $normalizeLocalPathAction $Path $Label
        & $assertNoReparseAction $full $Label
        if (-not (Test-Path -LiteralPath $full -PathType Container)) { return }
        $pending = New-Object 'System.Collections.Generic.Queue[string]'
        $pending.Enqueue($full)
        while ($pending.Count -gt 0) {
            $directory = $pending.Dequeue()
            foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
                if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "${Label}包含重解析点，拒绝执行: $($item.FullName)" }
                if ($item.PSIsContainer) { $pending.Enqueue($item.FullName) }
            }
        }
    }.GetNewClosure()

    $assertSafeRelativePathAction = {
        param([string]$Value, [string]$Label, [string]$ExpectedFirstSegment)
        if ([string]::IsNullOrWhiteSpace($Value) -or [IO.Path]::IsPathRooted($Value) -or $Value.Contains(':')) { throw "${Label}必须是安全的相对路径。" }
        $normalized = $Value.Replace('/', '\').TrimStart('\')
        $segments = @($normalized -split '\\')
        if ($segments.Count -eq 0 -or @($segments | Where-Object { -not $_ -or $_ -in @('.','..') }).Count -gt 0) { throw "${Label}包含越界路径段。" }
        if ($ExpectedFirstSegment -and -not $segments[0].Equals($ExpectedFirstSegment, [StringComparison]::OrdinalIgnoreCase)) {
            throw "${Label}不在目标 resource 内: $Value"
        }
        return $normalized
    }.GetNewClosure()

    $getFileHashAction = {
        param([string]$Path)
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }.GetNewClosure()

    $validatePlanAction = {
        param($Plan)
        if (-not $Plan -or [int]$Plan.schemaVersion -ne 1) { throw '仅支持 schemaVersion=1 的 Red40 方案。' }
        if (@($Plan.errors).Count -gt 0) { throw "方案包含 $(@($Plan.errors).Count) 个错误，不能用于生成或应用。" }

        $targetResource = & $assertGeneratedNameAction ([string]$Plan.targetResource) '方案目标 resource 名称'
        foreach ($pair in @(
            @([string]$Plan.settings.targetPrefix, '方案集合前缀'),
            @([string]$Plan.settings.femalePrefix, '方案女性集合前缀'),
            @([string]$Plan.settings.malePrefix, '方案男性集合前缀')
        )) { [void](& $assertGeneratedNameAction $pair[0] $pair[1]) }

        $roots = New-Object System.Collections.Generic.List[string]
        foreach ($rootValue in @($Plan.resourceRoots)) {
            $rootPath = & $normalizeLocalPathAction ([string]$rootValue) '方案 resource 根目录'
            if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) { throw "方案 resource 根目录不存在: $rootPath" }
            & $assertNoDescendantReparseAction $rootPath '方案 resource 根目录'
            if (-not $roots.Contains($rootPath)) { $roots.Add($rootPath) }
        }
        if ($roots.Count -eq 0) { throw '方案没有 resourceRoots。' }

        $generatedRoot = & $normalizeLocalPathAction ([string]$Plan.generatedResourcesRoot) '方案生成根目录'
        $generatedDiskRoot = [IO.Path]::GetPathRoot($generatedRoot).TrimEnd('\')
        if ($generatedRoot.Equals($generatedDiskRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '方案生成根目录不能是磁盘根目录。' }
        & $assertNoReparseAction $generatedRoot '方案生成根目录'
        foreach ($rootPath in $roots) {
            if (& $isPathAtOrInsideAction $generatedRoot $rootPath) { throw "方案生成根目录不能位于源 resource 内: $generatedRoot" }
        }

        $resourceNames = New-Object System.Collections.Generic.List[string]
        $absolutePaths = New-Object System.Collections.Generic.List[string]
        $existingPaths = New-Object System.Collections.Generic.List[string]
        foreach ($rootPath in $roots) {
            foreach ($manifestName in @('fxmanifest.lua','__resource.lua')) {
                $manifestPath = Join-Path $rootPath $manifestName
                if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                    $absolutePaths.Add($manifestPath)
                    $existingPaths.Add($manifestPath)
                    break
                }
            }
        }
        foreach ($source in @($Plan.sourceYmts)) {
            if ($source.resource) { $resourceNames.Add([string]$source.resource) }
            if ($source.path) { $absolutePaths.Add([string]$source.path); $existingPaths.Add([string]$source.path) }
            if ($source.collectionName) { [void](& $assertResourceNameAction ([string]$source.collectionName) '来源集合名称') }
            if ($source.fullCollectionName) { [void](& $assertResourceNameAction ([string]$source.fullCollectionName) '来源完整集合名称') }
        }
        foreach ($target in @($Plan.targetCollections)) {
            [void](& $assertGeneratedNameAction ([string]$target.collectionName) '目标集合名称')
            [void](& $assertGeneratedNameAction ([string]$target.fullCollectionName) '目标完整集合名称')
            [void](& $assertSafeRelativePathAction ([string]$target.outputYmtPath) '目标 YMT 输出路径' $targetResource)
            foreach ($path in @($target.sourceYmts)) { $absolutePaths.Add([string]$path); $existingPaths.Add([string]$path) }
            foreach ($range in @($target.componentRanges) + @($target.propRanges)) { if ($range.sourceYmtPath) { $absolutePaths.Add([string]$range.sourceYmtPath); $existingPaths.Add([string]$range.sourceYmtPath) } }
        }
        foreach ($mapping in @($Plan.drawableMappings) + @($Plan.propMappings)) {
            if ($mapping.sourceResource) { $resourceNames.Add([string]$mapping.sourceResource) }
            if ($mapping.sourceYmtPath) { $absolutePaths.Add([string]$mapping.sourceYmtPath); $existingPaths.Add([string]$mapping.sourceYmtPath) }
        }
        foreach ($rename in @($Plan.streamRenames)) {
            if ($rename.sourceResource) { $resourceNames.Add([string]$rename.sourceResource) }
            $sourcePath = & $normalizeLocalPathAction ([string]$rename.sourcePath) 'stream 改名源路径'
            $targetPath = & $normalizeLocalPathAction ([string]$rename.targetPath) 'stream 改名目标路径'
            $sourceRoot = & $getContainingRootAction $sourcePath $roots.ToArray()
            $targetRoot = & $getContainingRootAction $targetPath $roots.ToArray()
            if (-not $sourceRoot -or -not $targetRoot -or -not $sourceRoot.Equals($targetRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'stream 改名的源和目标不在同一个已批准 resource 内。' }
            $sourceRelative = $sourcePath.Substring($sourceRoot.Length).TrimStart('\')
            $targetRelative = $targetPath.Substring($targetRoot.Length).TrimStart('\')
            if (-not $sourceRelative.StartsWith('stream\', [StringComparison]::OrdinalIgnoreCase) -or -not $targetRelative.StartsWith('stream\', [StringComparison]::OrdinalIgnoreCase)) { throw 'stream 改名路径必须位于 resource 的 stream 目录。' }
            $absolutePaths.Add($sourcePath); $existingPaths.Add($sourcePath); $absolutePaths.Add($targetPath)
        }
        foreach ($backup in @($Plan.oldYmtBackups) + @($Plan.brokenCreatureMetadataBackups) + @($Plan.sourceAlternateMetadataBackups)) {
            if ($backup.sourcePath) { $absolutePaths.Add([string]$backup.sourcePath); $existingPaths.Add([string]$backup.sourcePath) }
            if ($backup.backupPath) { [void](& $assertSafeRelativePathAction ([string]$backup.backupPath) '方案备份相对路径' '') }
        }
        foreach ($item in @($Plan.missingCreatureMetadataReferences)) { if ($item.resource) { $resourceNames.Add([string]$item.resource) }; if ($item.shopMetaPath) { $absolutePaths.Add([string]$item.shopMetaPath); $existingPaths.Add([string]$item.shopMetaPath) } }
        foreach ($item in @($Plan.sourceManifestWarnings)) { if ($item.resource) { $resourceNames.Add([string]$item.resource) }; if ($item.manifestPath) { $absolutePaths.Add([string]$item.manifestPath); $existingPaths.Add([string]$item.manifestPath) } }
        foreach ($item in @($Plan.sourceCreatureMetadata)) { if ($item.resource) { $resourceNames.Add([string]$item.resource) }; if ($item.path) { $absolutePaths.Add([string]$item.path); $existingPaths.Add([string]$item.path) }; foreach ($path in @($item.sourceYmts)) { $absolutePaths.Add([string]$path); $existingPaths.Add([string]$path) } }
        foreach ($item in @($Plan.creatureMetadataOutputs)) {
            [void](& $assertResourceNameAction ([string]$item.name) '生物元数据名称')
            [void](& $assertSafeRelativePathAction ([string]$item.outputYmtPath) '生物元数据输出路径' $targetResource)
            foreach ($binding in @($item.sourceBindings)) { if ($binding.sourceYmtPath) { $absolutePaths.Add([string]$binding.sourceYmtPath); $existingPaths.Add([string]$binding.sourceYmtPath) }; if ($binding.sourceMetadataPath) { $absolutePaths.Add([string]$binding.sourceMetadataPath); $existingPaths.Add([string]$binding.sourceMetadataPath) } }
        }
        foreach ($item in @($Plan.sourceAlternateMetadata)) { if ($item.resource) { $resourceNames.Add([string]$item.resource) }; if ($item.path) { $absolutePaths.Add([string]$item.path); $existingPaths.Add([string]$item.path) } }
        foreach ($item in @($Plan.alternateMetadataOutputs)) { [void](& $assertSafeRelativePathAction ([string]$item.outputPath) '替代元数据输出路径' $targetResource); foreach ($path in @($item.sourcePaths)) { $absolutePaths.Add([string]$path); $existingPaths.Add([string]$path) } }

        foreach ($name in $resourceNames) { [void](& $assertResourceNameAction $name '方案 resource 名称') }
        foreach ($pathValue in $absolutePaths) {
            $full = & $normalizeLocalPathAction $pathValue '方案来源路径'
            if (-not (& $getContainingRootAction $full $roots.ToArray())) { throw "方案路径越出已批准 resource: $full" }
            & $assertNoReparseAction $full '方案来源路径'
        }
        foreach ($pathValue in $existingPaths) {
            $full = & $normalizeLocalPathAction $pathValue '方案来源文件'
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "方案来源文件不存在: $full" }
        }

        $requiredFiles = @($existingPaths | ForEach-Object { & $normalizeLocalPathAction $_ '方案来源文件' } | Sort-Object -Unique)
        $hashedSourceFiles = @($requiredFiles | Where-Object {
            $name = [IO.Path]::GetFileName($_)
            $extension = [IO.Path]::GetExtension($_)
            $extension -in @('.ymt','.xml','.meta') -or $name -in @('fxmanifest.lua','__resource.lua')
        })
        return [pscustomobject]@{
            Plan = $Plan
            ResourceRoots = $roots.ToArray()
            GeneratedResourcesRoot = $generatedRoot
            TargetResource = $targetResource
            RequiredFiles = $requiredFiles
            SourceFiles = $hashedSourceFiles
        }
    }.GetNewClosure()

    $writePlanTrustAction = {
        param([string]$PlanPath, $Seed)
        $fullPlan = & $normalizeLocalPathAction $PlanPath '方案文件'
        if (-not (Test-Path -LiteralPath $fullPlan -PathType Leaf)) { throw '分析完成但没有找到 plan.json。' }
        if ((Get-Item -LiteralPath $fullPlan).Length -gt 64MB) { throw '方案文件超过 64 MB 安全限制。' }
        $plan = Get-Content -LiteralPath $fullPlan -Raw -Encoding UTF8 | ConvertFrom-Json
        $validated = & $validatePlanAction $plan
        if (-not $validated.TargetResource.Equals([string]$Seed.TargetResource, [StringComparison]::OrdinalIgnoreCase)) { throw '方案目标 resource 与本次分析参数不一致。' }
        $expectedGenerated = & $normalizeLocalPathAction ([string]$Seed.GeneratedResourcesRoot) '本次生成根目录'
        if (-not $validated.GeneratedResourcesRoot.Equals($expectedGenerated, [StringComparison]::OrdinalIgnoreCase)) { throw '方案生成根目录与本次分析参数不一致。' }
        if ([string]$Seed.Mode -eq 'list') {
            $expectedRoots = @($Seed.ResourceRoots | ForEach-Object { & $normalizeLocalPathAction $_ '本次 resource 根目录' } | Sort-Object)
            $actualRoots = @($validated.ResourceRoots | Sort-Object)
            if (($expectedRoots -join "`n") -ine ($actualRoots -join "`n")) { throw '方案 resourceRoots 与本次逐项选择不一致。' }
        } else {
            $parent = & $normalizeLocalPathAction ([string]$Seed.SourceParent) '本次资源父目录'
            foreach ($rootPath in $validated.ResourceRoots) { if (-not (& $isPathAtOrInsideAction $rootPath $parent)) { throw "方案 resource 越出本次父目录: $rootPath" } }
        }
        $sourceRecords = @($validated.SourceFiles | ForEach-Object {
            [ordered]@{ path = [string]$_; sha256 = & $getFileHashAction ([string]$_) }
        })
        $record = [ordered]@{
            schemaVersion = 2
            kind = 'ck-clothing-plan'
            planPath = $fullPlan
            planSha256 = & $getFileHashAction $fullPlan
            resourceRoots = @($validated.ResourceRoots)
            generatedResourcesRoot = $validated.GeneratedResourcesRoot
            targetResource = $validated.TargetResource
            sourceFiles = $sourceRecords
            createdAt = (Get-Date).ToString('o')
        }
        [IO.File]::WriteAllText("$fullPlan.ck-plan.json", ($record | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
        $validated | Add-Member -NotePropertyName Trust -NotePropertyValue ([pscustomobject]$record) -Force
        return $validated
    }.GetNewClosure()

    $assertTrustedSourcesAction = {
        param($Validated, $Trust)
        if (-not $Trust.PSObject.Properties['sourceFiles']) { throw '方案旁车没有来源文件哈希，请重新执行分析。' }
        $expectedPaths = @($Validated.SourceFiles | Sort-Object)
        $records = @($Trust.sourceFiles | ForEach-Object { $_ })
        if ($records.Count -ne $expectedPaths.Count) { throw '方案旁车的来源文件清单与方案不一致，请重新执行分析。' }
        $recordMap = @{}
        foreach ($record in $records) {
            $path = & $normalizeLocalPathAction ([string]$record.path) '旁车来源文件'
            if ($recordMap.ContainsKey($path) -or -not [string]$record.sha256) { throw '方案旁车包含重复或无效的来源文件记录。' }
            $recordMap[$path] = ([string]$record.sha256).ToLowerInvariant()
        }
        foreach ($path in $expectedPaths) {
            if (-not $recordMap.ContainsKey($path)) { throw "方案旁车缺少来源文件记录: $path" }
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "分析后的来源文件已不存在，请重新分析: $path" }
            if ((& $getFileHashAction $path) -ine [string]$recordMap[$path]) { throw "分析后的来源文件已变化，请停止服务器并重新分析: $path" }
        }
    }.GetNewClosure()

    $assertRenameTargetsAction = {
        param($PlanInfo)
        foreach ($rename in @($PlanInfo.Plan.streamRenames)) {
            $sourcePath = & $normalizeLocalPathAction ([string]$rename.sourcePath) 'stream 改名源路径'
            $targetPath = & $normalizeLocalPathAction ([string]$rename.targetPath) 'stream 改名目标路径'
            if ($sourcePath.Equals($targetPath, [StringComparison]::OrdinalIgnoreCase)) { throw "stream 改名的源和目标相同: $sourcePath" }
            if (Test-Path -LiteralPath $targetPath) {
                & $assertNoReparseAction $targetPath 'stream 改名已有目标'
                throw "stream 改名目标已经存在。为避免复制结果错误或失败后覆盖源文件，请移走冲突目标并重新分析: $targetPath"
            }
        }
    }.GetNewClosure()

    $assertUniqueResourceNamesAction = {
        param($PlanInfo)
        $seen = @{}
        foreach ($rootPath in @($PlanInfo.ResourceRoots)) {
            $name = [IO.Path]::GetFileName(([string]$rootPath).TrimEnd('\'))
            if ($seen.ContainsKey($name)) { throw "多个源 resource 使用同名目录，apply 备份会互相覆盖，拒绝执行: $name`n$($seen[$name])`n$rootPath" }
            $seen[$name] = $rootPath
        }
    }.GetNewClosure()

    $assertUniqueBackupPathsAction = {
        param($PlanInfo)
        $seen = @{}
        $addBackupKey = {
            param([string]$RelativePath, [string]$SourceLabel)
            $key = (& $assertSafeRelativePathAction $RelativePath 'apply 备份相对路径' '').Replace('/', '\')
            if ($seen.ContainsKey($key)) { throw "多个源文件会写入同一个 apply 备份路径，拒绝执行: $key`n$($seen[$key])`n$SourceLabel" }
            $seen[$key] = $SourceLabel
        }

        $mergedYmtPaths = @{}
        foreach ($target in @($PlanInfo.Plan.targetCollections)) {
            foreach ($path in @($target.sourceYmts)) { $mergedYmtPaths[(& $normalizeLocalPathAction ([string]$path) '合并来源 YMT')] = $true }
        }
        foreach ($source in @($PlanInfo.Plan.sourceYmts)) {
            $sourcePath = & $normalizeLocalPathAction ([string]$source.path) '来源 YMT'
            if ($mergedYmtPaths.ContainsKey($sourcePath)) {
                & $addBackupKey (Join-Path ([string]$source.resource) ([IO.Path]::GetFileName($sourcePath))) $sourcePath
            }
        }
        foreach ($backup in @($PlanInfo.Plan.brokenCreatureMetadataBackups)) {
            & $addBackupKey ([string]$backup.backupPath) ([string]$backup.sourcePath)
        }
        $alternateBackups = @($PlanInfo.Plan.sourceAlternateMetadataBackups)
        if ($alternateBackups.Count -gt 0) {
            foreach ($backup in $alternateBackups) { & $addBackupKey ([string]$backup.backupPath) ([string]$backup.sourcePath) }
        } else {
            foreach ($source in @($PlanInfo.Plan.sourceAlternateMetadata)) {
                & $addBackupKey (Join-Path ([string]$source.resource) ([IO.Path]::GetFileName([string]$source.path))) ([string]$source.path)
            }
        }
        foreach ($rootPath in @($PlanInfo.ResourceRoots)) {
            foreach ($manifestName in @('fxmanifest.lua','__resource.lua')) {
                $manifestPath = Join-Path $rootPath $manifestName
                if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
                    $resourceName = [IO.Path]::GetFileName(([string]$rootPath).TrimEnd('\'))
                    & $addBackupKey (Join-Path $resourceName $manifestName) $manifestPath
                    break
                }
            }
        }
    }.GetNewClosure()

    $getTrustedPlanAction = {
        param([string]$PlanPath)
        $fullPlan = & $normalizeLocalPathAction $PlanPath '方案文件'
        $trustPath = "$fullPlan.ck-plan.json"
        if (-not (Test-Path -LiteralPath $trustPath -PathType Leaf)) { throw '该方案没有 CK 安全旁车记录。请先在本页面执行“分析打包方案”。' }
        $trust = Get-Content -LiteralPath $trustPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$trust.kind -ne 'ck-clothing-plan' -or [int]$trust.schemaVersion -ne 2) { throw 'CK 方案安全旁车格式无效或版本过旧，请重新执行分析。' }
        $actualHash = & $getFileHashAction $fullPlan
        if ($actualHash -ine [string]$trust.planSha256) { throw 'plan.json 已在分析后被修改，拒绝执行。请重新分析。' }
        $plan = Get-Content -LiteralPath $fullPlan -Raw -Encoding UTF8 | ConvertFrom-Json
        $validated = & $validatePlanAction $plan
        $trustedRoots = @($trust.resourceRoots | ForEach-Object { & $normalizeLocalPathAction $_ '旁车 resource 根目录' } | Sort-Object)
        $actualRoots = @($validated.ResourceRoots | Sort-Object)
        if (($trustedRoots -join "`n") -ine ($actualRoots -join "`n") -or
            $validated.GeneratedResourcesRoot -ine (& $normalizeLocalPathAction ([string]$trust.generatedResourcesRoot) '旁车生成根目录') -or
             $validated.TargetResource -ine [string]$trust.targetResource) { throw 'plan.json 的路径范围与 CK 安全旁车不一致。' }
        & $assertTrustedSourcesAction $validated $trust
        $validated | Add-Member -NotePropertyName Trust -NotePropertyValue $trust -Force
        $validated | Add-Member -NotePropertyName PlanPath -NotePropertyValue $fullPlan -Force
        return $validated
    }.GetNewClosure()

    $validateManifestAction = {
        param([string]$ManifestPath, $Trust, [bool]$CaptureBackupHashes = $false)
        $fullManifest = & $normalizeLocalPathAction $ManifestPath '备份清单'
        if (-not (Test-Path -LiteralPath $fullManifest -PathType Leaf)) { throw "备份清单不存在: $fullManifest" }
        if ((Get-Item -LiteralPath $fullManifest).Length -gt 64MB) { throw '备份清单超过 64 MB 安全限制。' }
        $backupRoot = & $normalizeLocalPathAction ([string]$Trust.backupRoot) '记录的备份根目录'
        $runRoot = & $normalizeLocalPathAction (Split-Path -Parent $fullManifest) '备份运行目录'
        if (-not (& $isPathAtOrInsideAction $runRoot $backupRoot) -or $runRoot.Equals($backupRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '备份清单不在记录的时间戳备份目录内。' }
        & $assertNoReparseAction $runRoot '备份运行目录'

        $resourceRoots = @($Trust.resourceRoots | ForEach-Object { & $normalizeLocalPathAction $_ '记录的 resource 根目录' })
        $generatedRoot = & $normalizeLocalPathAction ([string]$Trust.generatedResourcesRoot) '记录的生成根目录'
        $targetResource = & $assertGeneratedNameAction ([string]$Trust.targetResource) '记录的目标 resource 名称'
        $copyMode = ([bool]$Trust.copyMode)
        $copyRoots = @()
        if ($copyMode) {
            $copyRoots = @($resourceRoots | ForEach-Object { Join-Path $generatedRoot ([IO.Path]::GetFileName($_)) })
        }
        $allowedGenerated = @((@($copyRoots) + @(Join-Path $generatedRoot $targetResource)) | Select-Object -Unique)
        $allowedDataRoots = if ($copyMode) { @($copyRoots) } else { @($resourceRoots) }
        $parsedEntries = Get-Content -LiteralPath $fullManifest -Raw -Encoding UTF8 | ConvertFrom-Json
        $entries = @($parsedEntries | ForEach-Object { $_ })
        if ($entries.Count -eq 0 -or $entries.Count -gt 200000) { throw '备份清单条目数量不在安全范围内。' }
        $allowedKinds = @('generated-resource','stream-rename','old-ymt','broken-creature-metadata','source-alternate-metadata','resource-manifest')
        $counts = @{}
        $capturedBackupFiles = New-Object System.Collections.Generic.List[object]
        $trustedBackupHashes = @{}
        $trustedSourceHashes = @{}
        $trustedManifestHashes = @{}
        if ($CaptureBackupHashes) {
            if (-not $Trust.PSObject.Properties['sourceFiles']) { throw 'apply 记录缺少分析时的来源文件哈希。' }
            foreach ($record in @($Trust.sourceFiles | ForEach-Object { $_ })) {
                $recordPath = & $normalizeLocalPathAction ([string]$record.path) '分析来源文件'
                if ($trustedSourceHashes.ContainsKey($recordPath) -or -not [string]$record.sha256) { throw '分析来源文件哈希记录重复或无效。' }
                $trustedSourceHashes[$recordPath] = ([string]$record.sha256).ToLowerInvariant()
                if ([IO.Path]::GetFileName($recordPath) -in @('fxmanifest.lua','__resource.lua')) {
                    $trustedManifestHashes[$recordPath] = $trustedSourceHashes[$recordPath]
                }
            }
        } else {
            if (-not $Trust.PSObject.Properties['backupFiles']) { throw '恢复旁车没有独立备份文件哈希，请重新执行 apply。' }
            foreach ($record in @($Trust.backupFiles | ForEach-Object { $_ })) {
                $recordPath = & $normalizeLocalPathAction ([string]$record.path) '旁车备份文件'
                if ($trustedBackupHashes.ContainsKey($recordPath) -or -not [string]$record.sha256) { throw '恢复旁车包含重复或无效的备份文件记录。' }
                $trustedBackupHashes[$recordPath] = ([string]$record.sha256).ToLowerInvariant()
            }
        }
        $seenBackupPaths = @{}
        $seenResourceManifestOriginals = @{}
        foreach ($entry in $entries) {
            $kind = [string]$entry.kind
            if ($kind -notin $allowedKinds) { throw "备份清单包含未知 kind: $kind" }
            if (-not $counts.ContainsKey($kind)) { $counts[$kind] = 0 }
            $counts[$kind]++
            if ($kind -eq 'generated-resource') {
                $applied = & $normalizeLocalPathAction ([string]$entry.appliedPath) '生成资源恢复路径'
                $matched = @($allowedGenerated | Where-Object { $applied.Equals((& $normalizeLocalPathAction $_ '允许的生成目录'), [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
                if (-not $matched) { throw "备份清单试图删除未批准目录: $applied" }
                if (Test-Path -LiteralPath $applied) { & $assertNoDescendantReparseAction $applied '生成资源恢复路径' }
                continue
            }

            $original = & $normalizeLocalPathAction ([string]$entry.originalPath) '恢复原始路径'
            $originalRoot = & $getContainingRootAction $original $allowedDataRoots
            if (-not $originalRoot) { throw "恢复原始路径越出已批准 resource: $original" }
            & $assertNoReparseAction $original '恢复原始路径'

            if ($kind -eq 'stream-rename') {
                $applied = & $normalizeLocalPathAction ([string]$entry.appliedPath) 'stream 恢复来源'
                $appliedRoot = & $getContainingRootAction $applied $allowedDataRoots
                if (-not $appliedRoot -or -not $appliedRoot.Equals($originalRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'stream 恢复路径不在同一个已批准 resource。' }
                if ($original.Equals($applied, [StringComparison]::OrdinalIgnoreCase)) { throw 'stream 改名的原始路径与应用路径相同。' }
                $originalRelative = $original.Substring($originalRoot.Length).TrimStart('\')
                $appliedRelative = $applied.Substring($appliedRoot.Length).TrimStart('\')
                if (-not $originalRelative.StartsWith('stream\', [StringComparison]::OrdinalIgnoreCase) -or -not $appliedRelative.StartsWith('stream\', [StringComparison]::OrdinalIgnoreCase)) { throw 'stream 恢复路径必须位于 stream 目录。' }
                $originalExists = Test-Path -LiteralPath $original -PathType Leaf
                $appliedExists = Test-Path -LiteralPath $applied -PathType Leaf
                if ($appliedExists) { & $assertNoReparseAction $applied 'stream 恢复来源' }
                if (-not $copyMode) {
                    if ($originalExists -eq $appliedExists) { throw "原地 stream 改名状态不明确（两端同时存在或同时不存在），拒绝自动恢复: $original <-> $applied" }
                    if ($originalExists) {
                        if (-not $entry.sha256Before -or (& $getFileHashAction $original) -ine [string]$entry.sha256Before) { throw "尚未移动的 stream 源文件哈希不匹配: $original" }
                    } else {
                        $expectedAppliedHash = if ($entry.sha256After) { [string]$entry.sha256After } else { [string]$entry.sha256Before }
                        if (-not $expectedAppliedHash -or (& $getFileHashAction $applied) -ine $expectedAppliedHash) { throw "待恢复 stream 文件哈希不匹配: $applied" }
                    }
                } elseif ($appliedExists) {
                    $expectedAppliedHash = if ($entry.sha256After) { [string]$entry.sha256After } else { [string]$entry.sha256Before }
                    if ($expectedAppliedHash -and (& $getFileHashAction $applied) -ine $expectedAppliedHash) { throw "副本中的 stream 文件哈希不匹配: $applied" }
                }
                continue
            }

            $backupPath = & $normalizeLocalPathAction ([string]$entry.backupPath) '备份文件路径'
            if (-not (& $isPathAtOrInsideAction $backupPath $runRoot) -or $backupPath.Equals($runRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "备份文件越出时间戳目录: $backupPath" }
            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) { throw "备份文件不存在: $backupPath" }
            & $assertNoReparseAction $backupPath '备份文件路径'
            $actualBackupHash = & $getFileHashAction $backupPath
            if ($seenBackupPaths.ContainsKey($backupPath)) { throw "备份清单重复引用同一个备份文件: $backupPath" }
            $seenBackupPaths[$backupPath] = $true
            if ($CaptureBackupHashes) {
                if ($kind -eq 'resource-manifest') {
                    if ($seenResourceManifestOriginals.ContainsKey($original)) { throw "备份清单重复记录 resource manifest: $original" }
                    $seenResourceManifestOriginals[$original] = $true
                    if (-not $trustedSourceHashes.ContainsKey($original) -or $actualBackupHash -ine [string]$trustedSourceHashes[$original]) { throw "resource manifest 备份与分析时的来源哈希不匹配: $backupPath" }
                } elseif (-not $entry.sha256After -or $actualBackupHash -ine [string]$entry.sha256After) {
                    throw "备份文件与上游清单哈希不匹配: $backupPath"
                }
                $capturedBackupFiles.Add([pscustomobject][ordered]@{ path = $backupPath; sha256 = $actualBackupHash })
            } elseif (-not $trustedBackupHashes.ContainsKey($backupPath) -or $actualBackupHash -ine [string]$trustedBackupHashes[$backupPath]) {
                throw "备份文件与 CK 恢复旁车哈希不匹配: $backupPath"
            }
        }
        if ($CaptureBackupHashes) {
            foreach ($manifestPath in @($trustedManifestHashes.Keys)) {
                $manifestChanged = -not (Test-Path -LiteralPath $manifestPath -PathType Leaf)
                if (-not $manifestChanged) {
                    & $assertNoReparseAction $manifestPath 'apply 后的 resource manifest'
                    $manifestChanged = ((& $getFileHashAction $manifestPath) -ine [string]$trustedManifestHashes[$manifestPath])
                }
                if ($manifestChanged -and -not $seenResourceManifestOriginals.ContainsKey($manifestPath)) {
                    throw "resource manifest 已被改写或删除，但备份清单尚无对应恢复条目，拒绝标记为可信恢复: $manifestPath"
                }
            }
        }
        if (-not $CaptureBackupHashes -and $seenBackupPaths.Count -ne $trustedBackupHashes.Count) { throw '恢复旁车包含备份清单未引用的文件记录。' }
        return [pscustomobject]@{
            ManifestPath = $fullManifest
            Entries = $entries
            Counts = $counts
            DeletePaths = @($entries | Where-Object { $_.kind -eq 'generated-resource' } | ForEach-Object { [string]$_.appliedPath })
            CopyCount = @($entries | Where-Object { $_.kind -in @('old-ymt','broken-creature-metadata','source-alternate-metadata','resource-manifest') }).Count
            MoveCount = @($entries | Where-Object { $_.kind -eq 'stream-rename' }).Count
            BackupFiles = $capturedBackupFiles.ToArray()
        }
    }.GetNewClosure()

    $writeManifestTrustAction = {
        param([string]$ManifestPath, $ApplyContext)
        $planInfo = $ApplyContext.PlanInfo
        $record = [ordered]@{
            schemaVersion = 2
            kind = 'ck-clothing-backup'
            manifestPath = (& $normalizeLocalPathAction $ManifestPath '备份清单')
            manifestSha256 = & $getFileHashAction $ManifestPath
            planSha256 = [string]$planInfo.Trust.planSha256
            resourceRoots = @($planInfo.ResourceRoots)
            generatedResourcesRoot = [string]$planInfo.GeneratedResourcesRoot
            targetResource = [string]$planInfo.TargetResource
            copyMode = [bool]$ApplyContext.CopyMode
            backupRoot = [string]$ApplyContext.BackupRoot
            sourceFiles = @($planInfo.Trust.sourceFiles)
            createdAt = (Get-Date).ToString('o')
        }
        $validated = & $validateManifestAction $ManifestPath ([pscustomobject]$record) $true
        $record['backupFiles'] = @($validated.BackupFiles)
        [IO.File]::WriteAllText("$ManifestPath.ck-restore.json", ($record | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
        return [pscustomobject]$record
    }.GetNewClosure()

    $getTrustedManifestAction = {
        param([string]$ManifestPath)
        $fullManifest = & $normalizeLocalPathAction $ManifestPath '备份清单'
        $trustPath = "$fullManifest.ck-restore.json"
        if (-not (Test-Path -LiteralPath $trustPath -PathType Leaf)) { throw '该备份清单没有 CK 安全旁车记录，只能恢复由本页面 apply 生成并记录的备份。' }
        $trust = Get-Content -LiteralPath $trustPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]$trust.kind -ne 'ck-clothing-backup' -or [int]$trust.schemaVersion -ne 2) { throw 'CK 恢复安全旁车格式无效或版本过旧。' }
        if ((& $getFileHashAction $fullManifest) -ine [string]$trust.manifestSha256) { throw 'backup-manifest.json 已在 apply 后被修改，拒绝恢复。' }
        $validated = & $validateManifestAction $fullManifest $trust
        $validated | Add-Member -NotePropertyName Trust -NotePropertyValue $trust -Force
        return $validated
    }.GetNewClosure()

    $buildCommandAction = {
        $key = & $getCommandKeyAction
        $arguments = New-Object System.Collections.Generic.List[string]
        $resultPath = ''
        $displayName = ''
        $trustContext = $null
        $applyBackupRoot = ''
        $existingManifests = @()
        switch ($key) {
            'analyze' {
                $displayName = '分析打包方案'
                $arguments.Add('analyze')
                $mode = if ($ui.AnalyzeInputModeBox.SelectedItem) { [string]$ui.AnalyzeInputModeBox.SelectedItem.Tag } else { 'parent' }
                if ($mode -eq 'list') {
                    $selectedRoots = @(& $getResourcePathsAction $ui.AnalyzeResourcesBox.Text)
                    foreach ($path in $selectedRoots) { & $assertNoDescendantReparseAction $path 'resource 目录'; $arguments.Add('--resource'); $arguments.Add($path) }
                    $generatedRoot = & $getOutputDirectoryAction $ui.AnalyzeGeneratedRootBox.Text '生成资源父目录' $false
                    $arguments.Add('--generated-root'); $arguments.Add($generatedRoot)
                } else {
                    $resources = & $getExistingDirectoryAction $ui.AnalyzeParentBox.Text '资源父目录' $true
                    & $assertNoDescendantReparseAction $resources '资源父目录'
                    $arguments.Add('--resources'); $arguments.Add($resources)
                    $generatedRoot = [IO.Path]::GetDirectoryName($resources)
                    $generatedDiskRoot = [IO.Path]::GetPathRoot($generatedRoot).TrimEnd('\')
                    if ($generatedRoot.TrimEnd('\').Equals($generatedDiskRoot, [StringComparison]::OrdinalIgnoreCase)) { throw '父目录模式会把生成根目录设为磁盘根目录；请改用逐个指定 resource 模式并选择独立输出。' }
                }
                $targetResource = & $assertGeneratedNameAction $ui.TargetResourceBox.Text '目标 resource 名称'
                $targetPrefix = & $assertGeneratedNameAction $ui.TargetPrefixBox.Text '集合前缀'
                $outPath = & $getOutputFileAction $ui.AnalyzePlanBox.Text '方案文件'
                $maxComponent = & $getPositiveIntAction $ui.MaxComponentBox.Text '组件 drawable 上限'
                $maxProp = & $getPositiveIntAction $ui.MaxPropBox.Text 'prop drawable 上限'
                $arguments.Add('--target-resource'); $arguments.Add($targetResource)
                $arguments.Add('--target-prefix'); $arguments.Add($targetPrefix)
                if ($ui.FemalePrefixBox.Text.Trim()) { $arguments.Add('--female-prefix'); $arguments.Add((& $assertGeneratedNameAction $ui.FemalePrefixBox.Text '女性集合前缀')) }
                if ($ui.MalePrefixBox.Text.Trim()) { $arguments.Add('--male-prefix'); $arguments.Add((& $assertGeneratedNameAction $ui.MalePrefixBox.Text '男性集合前缀')) }
                $arguments.Add('--max-drawables-per-component'); $arguments.Add([string]$maxComponent)
                $arguments.Add('--max-drawables-per-prop'); $arguments.Add([string]$maxProp)
                if ($ui.OptimizeCheck.IsChecked -eq $true) { $arguments.Add('--optimize-ymt-usage') }
                $arguments.Add('--out'); $arguments.Add($outPath)
                $resultPath = $outPath
                $trustContext = if ($mode -eq 'list') {
                    [pscustomobject]@{ Kind = 'analyze-seed'; Mode = 'list'; ResourceRoots = $selectedRoots; SourceParent = ''; GeneratedResourcesRoot = $generatedRoot; TargetResource = $targetResource }
                } else {
                    [pscustomobject]@{ Kind = 'analyze-seed'; Mode = 'parent'; ResourceRoots = @(); SourceParent = $resources; GeneratedResourcesRoot = $generatedRoot; TargetResource = $targetResource }
                }
            }
            'build' {
                $displayName = '生成合并资源'
                $plan = & $getExistingFileAction $ui.BuildPlanBox.Text '方案文件'
                $planInfo = & $getTrustedPlanAction $plan
                $output = & $getOutputDirectoryAction $ui.BuildOutputBox.Text '预览输出目录' $true
                foreach ($rootPath in $planInfo.ResourceRoots) {
                    if ((& $isPathAtOrInsideAction $output $rootPath) -or (& $isPathAtOrInsideAction $rootPath $output)) { throw "预览输出目录不能与源 resource 重叠: $rootPath" }
                }
                if ($output.Equals((& $normalizeLocalPathAction $Context.Paths.ScriptRoot '工具箱目录'), [StringComparison]::OrdinalIgnoreCase) -or
                    $output.Equals((& $normalizeLocalPathAction $Context.Paths.WorkspaceRoot '工作区目录'), [StringComparison]::OrdinalIgnoreCase)) { throw '预览输出目录不能直接使用工具箱或工作区根目录。' }
                & $assertNoReparseAction $output '预览输出目录'
                $buildTarget = Join-Path $output ([string]$planInfo.TargetResource)
                if (Test-Path -LiteralPath $buildTarget) { & $assertNoDescendantReparseAction $buildTarget '预览已有目标' }
                $arguments.Add('build'); $arguments.Add('--plan'); $arguments.Add($plan); $arguments.Add('--out'); $arguments.Add($output)
                $arguments.Add('--include-ymt-xml'); $arguments.Add($(if ($ui.BuildXmlCheck.IsChecked -eq $true) { 'true' } else { 'false' }))
                $arguments.Add('--include-debug-client'); $arguments.Add($(if ($ui.BuildDebugCheck.IsChecked -eq $true) { 'true' } else { 'false' }))
                $resultPath = $output
                $trustContext = $planInfo
            }
            'apply' {
                $displayName = '应用方案到资源'
                $plan = & $getExistingFileAction $ui.ApplyPlanBox.Text '方案文件'
                $planInfo = & $getTrustedPlanAction $plan
                $copyMode = ($ui.CopyResourcesCheck.IsChecked -eq $true)
                & $assertUniqueResourceNamesAction $planInfo
                if (-not $copyMode) { & $assertUniqueBackupPathsAction $planInfo }
                & $assertRenameTargetsAction $planInfo
                $backupBase = & $getOutputDirectoryAction $ui.ApplyBackupBox.Text '备份根目录' $true
                $backup = Join-Path $backupBase ("ck-apply-{0}-{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), [guid]::NewGuid().ToString('N').Substring(0, 8))
                $protectedRoots = @(
                    (& $normalizeLocalPathAction $Context.Paths.ScriptRoot '工具箱目录'),
                    (& $normalizeLocalPathAction $Context.Paths.WorkspaceRoot '工作区目录')
                )
                if (@($protectedRoots | Where-Object { $planInfo.GeneratedResourcesRoot.Equals($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { throw '方案生成根目录不能直接使用工具箱或工作区根目录。请重新用逐项 resource 模式分析，并选择独立输出。' }
                if (@($protectedRoots | Where-Object { $backup.Equals($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { throw '备份根目录不能直接使用工具箱或工作区根目录。' }
                foreach ($rootPath in $planInfo.ResourceRoots) {
                    if ((& $isPathAtOrInsideAction $backup $rootPath) -or (& $isPathAtOrInsideAction $rootPath $backup)) { throw "备份根目录不能与源 resource 重叠: $rootPath" }
                }
                if ((& $isPathAtOrInsideAction $backup $planInfo.GeneratedResourcesRoot) -or (& $isPathAtOrInsideAction $planInfo.GeneratedResourcesRoot $backup)) { throw '备份根目录不能与方案生成根目录重叠。' }
                & $assertNoReparseAction $backup '备份根目录'
                $destinations = New-Object System.Collections.Generic.List[string]
                $destinationOwners = @{}
                if ($copyMode) {
                    foreach ($rootPath in $planInfo.ResourceRoots) {
                        $destination = & $normalizeLocalPathAction (Join-Path $planInfo.GeneratedResourcesRoot ([IO.Path]::GetFileName($rootPath))) 'resource 复制目标'
                        if ($destinationOwners.ContainsKey($destination)) { throw "多个源 resource 会写入同一个复制目标: $destination" }
                        $destinationOwners[$destination] = $rootPath
                        $destinations.Add($destination)
                    }
                }
                $targetDestination = & $normalizeLocalPathAction (Join-Path $planInfo.GeneratedResourcesRoot $planInfo.TargetResource) '合并 resource 目标'
                if (-not $destinationOwners.ContainsKey($targetDestination)) {
                    $destinationOwners[$targetDestination] = '<target-resource>'
                    $destinations.Add($targetDestination)
                }

                foreach ($destination in $destinations) {
                    $parent = & $normalizeLocalPathAction (Split-Path -Parent $destination) 'apply 目标父目录'
                    if (-not $parent.Equals($planInfo.GeneratedResourcesRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "apply 目标不是生成根目录的直接子目录: $destination" }
                    foreach ($rootPath in $planInfo.ResourceRoots) {
                        if ((& $isPathAtOrInsideAction $destination $rootPath) -or (& $isPathAtOrInsideAction $rootPath $destination)) {
                            throw "apply 目标与源 resource 重叠，拒绝执行: $destination <-> $rootPath"
                        }
                    }
                    foreach ($protectedRoot in $protectedRoots) {
                        if ($destination.Equals($protectedRoot, [StringComparison]::OrdinalIgnoreCase) -or (& $isPathAtOrInsideAction $protectedRoot $destination)) {
                            throw "apply 目标会覆盖工具箱或工作区根目录，拒绝执行: $destination"
                        }
                    }
                    if (Test-Path -LiteralPath $destination) {
                        & $assertNoReparseAction $destination 'apply 已有目标'
                        throw "apply 目标已经存在，而上游 CLI 会递归删除且无法通过本次 restore 找回。请先自行备份并移走该目录，或重新分析到空的生成根目录: $destination"
                    }
                }
                $arguments.Add('apply'); $arguments.Add('--plan'); $arguments.Add($plan); $arguments.Add('--backup-root'); $arguments.Add($backup)
                if ($copyMode) { $arguments.Add('--copy-resources-to-output') }
                $arguments.Add('--include-ymt-xml'); $arguments.Add($(if ($ui.ApplyXmlCheck.IsChecked -eq $true) { 'true' } else { 'false' }))
                $arguments.Add('--include-debug-client'); $arguments.Add($(if ($ui.ApplyDebugCheck.IsChecked -eq $true) { 'true' } else { 'false' }))
                $resultPath = $backup
                $existingManifests = @(Get-ChildItem -LiteralPath $backup -Filter 'backup-manifest.json' -File -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
                $trustContext = [pscustomobject]@{ Kind = 'apply'; PlanInfo = $planInfo; CopyMode = $copyMode; BackupRoot = $backup; Destinations = $destinations.ToArray() }
                $applyBackupRoot = $backup
            }
            'restore' {
                $displayName = '恢复已应用修改'
                $manifest = & $getExistingFileAction $ui.RestoreManifestBox.Text '备份清单'
                $manifestInfo = & $getTrustedManifestAction $manifest
                $arguments.Add('restore'); $arguments.Add('--backup-manifest'); $arguments.Add($manifest)
                $resultPath = Split-Path -Parent $manifest
                $trustContext = $manifestInfo
            }
            'validate-plan' {
                $displayName = '校验方案文件'
                $plan = & $getExistingFileAction $ui.ValidatePlanBox.Text '方案文件'
                $arguments.Add('validate'); $arguments.Add('--plan'); $arguments.Add($plan)
                $resultPath = $plan
            }
            'validate-parent' {
                $displayName = '校验资源父目录'
                $resources = & $getExistingDirectoryAction $ui.ValidateParentBox.Text '资源父目录' $true
                & $assertNoDescendantReparseAction $resources '资源父目录'
                $arguments.Add('validate'); $arguments.Add('--resources'); $arguments.Add($resources)
                $resultPath = $resources
            }
            'validate-list' {
                $displayName = '校验指定资源列表'
                $arguments.Add('validate')
                foreach ($path in @(& $getResourcePathsAction $ui.ValidateResourcesBox.Text)) { & $assertNoDescendantReparseAction $path 'resource 目录'; $arguments.Add('--resource'); $arguments.Add($path) }
                $generatedRoot = & $getOutputDirectoryAction $ui.ValidateGeneratedRootBox.Text '生成资源父目录' $false
                $arguments.Add('--generated-root'); $arguments.Add($generatedRoot)
                $resultPath = $generatedRoot
            }
            'report' {
                $displayName = '生成打包报告'
                $plan = & $getExistingFileAction $ui.ReportPlanBox.Text '方案文件'
                $arguments.Add('report'); $arguments.Add('--plan'); $arguments.Add($plan)
                if ($ui.ReportOutputBox.Text.Trim()) {
                    $reportOutput = & $getOutputFileAction $ui.ReportOutputBox.Text '报告文件'
                    $arguments.Add('--out'); $arguments.Add($reportOutput)
                    $resultPath = $reportOutput
                } else { $resultPath = $plan }
            }
            'export-xml' {
                $displayName = '导出 YMT XML'
                $folder = & $getExistingDirectoryAction $ui.ExportFolderBox.Text 'YMT 目录' $true
                & $assertNoDescendantReparseAction $folder 'YMT 目录'
                $arguments.Add('export-xml'); $arguments.Add('--folder'); $arguments.Add($folder)
                if ($ui.ExportOverwriteCheck.IsChecked -eq $true) { $arguments.Add('--overwrite') }
                $resultPath = $folder
            }
            default { throw "不支持的 CLI 功能: $key" }
        }
        if ($ui.NoVersionCheckCheck.IsChecked -eq $true) { $arguments.Add('--no-version-check') }
        return [pscustomobject]@{
            Key = $key
            DisplayName = $displayName
            Arguments = $arguments.ToArray()
            ResultPath = $resultPath
            TrustContext = $trustContext
            ApplyBackupRoot = $applyBackupRoot
            ExistingManifests = @($existingManifests)
        }
    }.GetNewClosure()

    $confirmCommandAction = {
        param($Command)
        if ($Command.Key -eq 'analyze' -and (Test-Path -LiteralPath $Command.ResultPath -PathType Leaf)) {
            $answer = [System.Windows.MessageBox]::Show("方案文件已存在，将覆盖并重新生成安全旁车记录：`n`n$($Command.ResultPath)`n`n是否继续？", '确认覆盖方案', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return $false }
        }
        if ($Command.Key -eq 'build') {
            $targetPath = Join-Path $Command.ResultPath ([string]$Command.TrustContext.TargetResource)
            if (Test-Path -LiteralPath $targetPath) {
                $answer = [System.Windows.MessageBox]::Show("预览目标已经存在，CLI 会覆盖同名输出文件：`n`n$targetPath`n`n是否继续？", '确认覆盖预览输出', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return $false }
            }
        }
        if ($Command.Key -eq 'apply') {
            $existing = @($Command.TrustContext.Destinations | Where-Object { Test-Path -LiteralPath $_ })
            if ($existing.Count) {
                throw "apply 目标在确认期间已出现。为避免递归删除无法恢复的内容，已取消执行：`n$($existing -join "`n")"
            }
            if ($ui.CopyResourcesCheck.IsChecked -eq $true) {
                $answer = [System.Windows.MessageBox]::Show("apply 将复制所选 resources 后处理副本，并创建新的合并 resource。`n`n本次独立备份根目录：$($Command.ApplyBackupRoot)`n`n是否继续？", '确认复制并应用方案', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
                return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
            }
            $answer = [System.Windows.MessageBox]::Show(
                "你已关闭【复制后处理】。本次 apply 会直接重命名源 resource 的 stream 文件，并移走源 YMT。`n`n虽然会生成备份，但仍建议先停止服务器并另做完整备份。是否继续？",
                '确认直接修改源资源',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
        }
        if ($Command.Key -eq 'restore') {
            $manifestInfo = $Command.TrustContext
            $deleteText = if ($manifestInfo.DeletePaths.Count) { $manifestInfo.DeletePaths -join "`n" } else { '无' }
            $answer = [System.Windows.MessageBox]::Show(
                "恢复顺序为：递归删除生成目录、覆盖复制备份、覆盖移动 stream。`n`n将删除：`n$deleteText`n`n覆盖复制：$($manifestInfo.CopyCount) 项`n覆盖移动：$($manifestInfo.MoveCount) 项`n`n清单哈希和备份文件哈希已通过。请确认服务器已停止。是否继续？",
                '确认恢复衣服资源',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
        }
        if ($Command.Key -eq 'export-xml' -and $ui.ExportOverwriteCheck.IsChecked -eq $true) {
            $answer = [System.Windows.MessageBox]::Show(
                '已启用覆盖同名 .ymt.xml。是否继续？',
                '确认覆盖 XML',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Warning
            )
            return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
        }
        if ($Command.Key -eq 'report' -and $ui.ReportOutputBox.Text.Trim() -and (Test-Path -LiteralPath $Command.ResultPath -PathType Leaf)) {
            $answer = [System.Windows.MessageBox]::Show("报告文件已存在，将被覆盖：`n`n$($Command.ResultPath)`n`n是否继续？", '确认覆盖报告', [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            return ($answer -eq [System.Windows.MessageBoxResult]::Yes)
        }
        return $true
    }.GetNewClosure()

    $formatArgumentsAction = {
        param([string[]]$Arguments)
        return (($Arguments | ForEach-Object { if ($_ -match '[\s"]') { '"' + $_.Replace('"','\"') + '"' } else { $_ } }) -join ' ')
    }.GetNewClosure()

    $translateCliStatusAction = {
        param([string]$Text)
        switch -Regex ($Text) {
            '^\[analyze\]' { return '正在分析服装资源并规划合并结果；详细进度见任务日志。' }
            '^\[build\]' { return '正在生成合并资源；详细进度见任务日志。' }
            '^\[apply\]' { return '正在应用方案并写入备份；详细进度见任务日志。' }
            '^\[restore\]' { return '正在按备份清单恢复资源；详细进度见任务日志。' }
            '^\[export-xml\]' { return '正在导出 YMT XML；详细进度见任务日志。' }
            '^Analyzed\s' { return '资源分析已完成；数量与警告统计见任务日志。' }
            '^Wrote\s.+file\(s\)' { return '合并资源已生成；写入统计见任务日志。' }
            '^Wrote YMT repack report\s' { return '打包报告已生成。' }
            '^Applied plan\s' { return '方案已应用；备份条目统计见任务日志。' }
            '^Restore complete\.' { return '资源恢复已完成。' }
            '^Plan is valid\.' { return '方案校验通过。' }
            '^Plan has\s' { return '方案校验未通过；错误详情见任务日志。' }
            '^Resources validated\.' { return '资源校验通过。' }
            '^Resources have\s' { return '资源校验未通过；错误详情见任务日志。' }
            '^Exported\s' { return 'YMT XML 导出完成；数量统计见任务日志。' }
            '^Skipped\s' { return '部分已有 XML 已跳过；数量统计见任务日志。' }
            default { return '' }
        }
    }.GetNewClosure()

    $setRunningAction = {
        param([bool]$Running)
        $ui.CommandBox.IsEnabled = -not $Running
        $ui.NoVersionCheckCheck.IsEnabled = -not $Running
        $ui.StartButton.IsEnabled = -not $Running
        $ui.StopButton.IsEnabled = $Running
        if ($Running) {
            $ui.ProgressBar.IsIndeterminate = $true
            $ui.ProgressBar.Value = 8
            $ui.ResultStatus.Text = '正在运行'
            $ui.ResultStatus.Foreground = (Get-CkThemeBrush '#72B7F2')
            $ui.StatusLine.Text = 'CLI 正在处理，请留意日志中的警告与错误。'
        } else { $ui.ProgressBar.IsIndeterminate = $false }
    }.GetNewClosure()

    $saveLogAction = {
        $logRoot = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'CKFreeToolbox') 'clothing-repacker-reports'
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
        $path = Join-Path $logRoot ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + $state.CommandKey + '.log')
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('CK免费工具箱 - Red40 Clothing Repacker CLI 任务日志')
        $lines.Add("开始时间: $($state.StartedAt)")
        $lines.Add("功能: $($state.CommandName)")
        $lines.Add("程序: $($Context.Paths.ClothingRepackerExe)")
        $lines.Add("参数: $(& $formatArgumentsAction $state.Arguments)")
        $lines.Add('')
        $lines.Add($state.Output.ToString().TrimEnd())
        [IO.File]::WriteAllText($path, ($lines -join [Environment]::NewLine), (New-Object Text.UTF8Encoding($false)))
        $state.LogPath = $path
        $ui.OpenLogButton.IsEnabled = $true
        return $path
    }.GetNewClosure()

    $startAction = {
        if ($state.Process -and -not $state.Process.Process.HasExited) { throw '已有衣服资源 CLI 任务正在运行。' }
        if (-not (Test-Path -LiteralPath $Context.Paths.ClothingRepackerExe -PathType Leaf)) { throw 'Red40 CLI 组件未安装，请先点击顶部“安装组件”。' }
        $command = & $buildCommandAction
        if (-not (& $confirmCommandAction $command)) { return }
        if ($command.Key -eq 'build') {
            & $assertTrustedSourcesAction $command.TrustContext $command.TrustContext.Trust
        } elseif ($command.Key -eq 'apply') {
            & $assertTrustedSourcesAction $command.TrustContext.PlanInfo $command.TrustContext.PlanInfo.Trust
            if (-not $command.TrustContext.CopyMode) { & $assertUniqueBackupPathsAction $command.TrustContext.PlanInfo }
            & $assertRenameTargetsAction $command.TrustContext.PlanInfo
        }

        $state.CancelRequested = $false
        $state.StartedAt = Get-Date
        $state.CommandKey = [string]$command.Key
        $state.CommandName = [string]$command.DisplayName
        $state.Arguments = @($command.Arguments)
        $state.Output = New-Object Text.StringBuilder
        $state.LogPath = ''
        $state.ResultPath = [string]$command.ResultPath
        $state.TrustContext = $command.TrustContext
        $state.ApplyBackupRoot = [string]$command.ApplyBackupRoot
        $state.ExistingManifests = @($command.ExistingManifests)
        $ui.OpenLogButton.IsEnabled = $false
        $ui.OpenResultButton.IsEnabled = $false
        $commandLine = & $formatArgumentsAction $state.Arguments
        $ui.LogBox.Text = (@('开始 Red40 Clothing Repacker CLI 任务...', "功能: $($state.CommandName)", "参数: $commandLine", '') -join [Environment]::NewLine)
        & $setRunningAction $true

        $callbackState = $state
        $callbackUi = $ui
        $callbackSetRunning = $setRunningAction
        $callbackSaveLog = $saveLogAction
        $callbackUpdateEnvironment = $updateEnvironmentAction
        $callbackWritePlanTrust = $writePlanTrustAction
        $callbackWriteManifestTrust = $writeManifestTrustAction
        $callbackTranslateCliStatus = $translateCliStatusAction

        $onOutput = {
            param($Line)
            $text = [string]$Line
            [void]$callbackState.Output.AppendLine($text)
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line $text
            $translatedStatus = & $callbackTranslateCliStatus $text
            if ($translatedStatus) { $callbackUi.StatusLine.Text = $translatedStatus }
        }.GetNewClosure()

        $onProcessError = {
            param($Message)
            $rawMessage = [string]$Message
            [void]$callbackState.Output.AppendLine("[工具箱内部错误] $rawMessage")
            Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱内部错误] $rawMessage"
            $callbackUi.StatusLine.Text = '处理 CLI 输出时发生内部错误，请查看任务日志。'
        }.GetNewClosure()

        $onExit = {
            param($ExitCode)
            $cancelled = $callbackState.CancelRequested
            $callbackState.CancelRequested = $false
            $callbackState.Process = $null
            & $callbackSetRunning $false
            $safetyError = ''
            $trustedRestorePath = ''
            if (-not $cancelled -and $ExitCode -eq 0 -and $callbackState.CommandKey -eq 'analyze') {
                try {
                    [void](& $callbackWritePlanTrust $callbackState.ResultPath $callbackState.TrustContext)
                    $toolboxLine = "[工具箱] 已写入方案、来源文件哈希与路径范围旁车: $($callbackState.ResultPath).ck-plan.json"
                    [void]$callbackState.Output.AppendLine($toolboxLine)
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                } catch { $safetyError = "方案安全校验失败: $($_.Exception.Message)" }
            }
            if ($callbackState.CommandKey -eq 'apply' -and $callbackState.ApplyBackupRoot) {
                try {
                    $newManifests = @(Get-ChildItem -LiteralPath $callbackState.ApplyBackupRoot -Filter 'backup-manifest.json' -File -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -notin @($callbackState.ExistingManifests) } |
                        Sort-Object LastWriteTimeUtc -Descending)
                    if ($newManifests.Count -gt 0) {
                        [void](& $callbackWriteManifestTrust $newManifests[0].FullName $callbackState.TrustContext)
                        $callbackState.ResultPath = $newManifests[0].DirectoryName
                        $trustedRestorePath = $newManifests[0].FullName
                        $toolboxLine = "[工具箱] 已校验备份清单并写入恢复旁车: $($newManifests[0].FullName).ck-restore.json"
                        [void]$callbackState.Output.AppendLine($toolboxLine)
                        Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                    } else {
                        $safetyError = 'apply 没有生成可验证的 backup-manifest.json；可能存在不完整输出，不能依赖自动 restore。'
                    }
                } catch {
                    $manifestError = "备份清单安全校验失败: $($_.Exception.Message)"
                    if ($safetyError) { $safetyError += " | $manifestError" } else { $safetyError = $manifestError }
                }
            }
            if ($cancelled) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务已停止'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#F4B860')
                if ($callbackState.CommandKey -eq 'apply' -and -not $trustedRestorePath) {
                    $callbackUi.StatusLine.Text = 'apply 已停止且没有可信恢复记录；输出可能不完整，请勿启动服务器，并手动检查生成目录与备份目录。'
                    if (-not $safetyError) { $safetyError = 'apply 被停止且没有可信恢复记录；需要手动检查和清理不完整输出。' }
                    $toolboxLine = "[工具箱] $safetyError"
                    [void]$callbackState.Output.AppendLine($toolboxLine)
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                } elseif ($callbackState.CommandKey -eq 'apply') {
                    $callbackUi.StatusLine.Text = "apply 已停止；已生成可信恢复记录，可用【恢复已应用修改】检查并恢复：$trustedRestorePath"
                    $toolboxLine = "[工具箱] apply 被停止；可信恢复清单: $trustedRestorePath"
                    [void]$callbackState.Output.AppendLine($toolboxLine)
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                } else {
                    $callbackUi.StatusLine.Text = 'CLI 已停止；已经写出的文件不会自动回滚。'
                }
            } elseif ($ExitCode -ne 0 -or $safetyError) {
                $callbackUi.ProgressBar.Value = 0
                $callbackUi.ResultStatus.Text = '任务失败'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#EF7C86')
                $callbackUi.StatusLine.Text = if ($safetyError) { $safetyError } elseif ($trustedRestorePath) { "CLI 退出码: ${ExitCode}；存在可信恢复清单，可检查并恢复：$trustedRestorePath" } else { "CLI 退出码: ${ExitCode}。请查看日志中的具体错误。" }
                if ($safetyError) {
                    $toolboxLine = "[工具箱] $safetyError"
                    [void]$callbackState.Output.AppendLine($toolboxLine)
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                } elseif ($trustedRestorePath) {
                    $toolboxLine = "[工具箱] apply 异常退出，但存在可信恢复清单: $trustedRestorePath"
                    [void]$callbackState.Output.AppendLine($toolboxLine)
                    Add-CkLogLine -TextBox $callbackUi.LogBox -Line $toolboxLine
                }
            } else {
                $callbackUi.ProgressBar.Value = 100
                $callbackUi.ResultStatus.Text = '任务完成'
                $callbackUi.ResultStatus.Foreground = (Get-CkThemeBrush '#31D69A')
                $callbackUi.StatusLine.Text = "$($callbackState.CommandName)已完成，请检查日志中的警告与统计。"
            }
            $logPath = ''
            try { $logPath = & $callbackSaveLog } catch { }
            $callbackUi.OpenResultButton.IsEnabled = [bool]($callbackState.ResultPath -and (Test-Path -LiteralPath $callbackState.ResultPath))
            if ($logPath) { Add-CkLogLine -TextBox $callbackUi.LogBox -Line "[工具箱] 本次日志: $logPath" }
            & $callbackUpdateEnvironment
        }.GetNewClosure()

        try {
            $state.Process = Start-CkLoggedProcess -FileName $Context.Paths.ClothingRepackerExe -Arguments $state.Arguments -WorkingDirectory $Context.Paths.ClothingRepackerDir -Dispatcher $Context.Dispatcher -OnOutput $onOutput -OnExit $onExit -OnError $onProcessError
        } catch {
            & $setRunningAction $false
            throw
        }
    }.GetNewClosure()

    $stopAction = {
        if (-not $state.Process -or $state.Process.Process.HasExited) { return }
        $state.CancelRequested = $true
        $ui.StopButton.IsEnabled = $false
        $ui.ResultStatus.Text = '正在停止'
        $ui.StatusLine.Text = '正在停止 Red40 CLI 及其子进程...'
        $pidToStop = $state.Process.Process.Id
        try {
            $killerInfo = New-Object Diagnostics.ProcessStartInfo
            $killerInfo.FileName = 'taskkill.exe'
            $killerInfo.Arguments = "/PID $pidToStop /T /F"
            $killerInfo.UseShellExecute = $false
            $killerInfo.CreateNoWindow = $true
            $killer = [Diagnostics.Process]::Start($killerInfo)
            if ($killer) { [void]$killer.WaitForExit(5000); $killer.Dispose() }
            if (-not $state.Process.Process.HasExited) { $state.Process.Process.Kill() }
        } catch {
            $state.CancelRequested = $false
            throw "停止任务失败: $($_.Exception.Message)"
        }
    }.GetNewClosure()

    $openResultAction = {
        $path = [string]$state.ResultPath
        if (-not $path -or -not (Test-Path -LiteralPath $path)) { throw '本次任务结果不存在。' }
        if (Test-Path -LiteralPath $path -PathType Container) { Start-Process -FilePath explorer.exe -ArgumentList @($path) }
        else { Start-Process -FilePath explorer.exe -ArgumentList @((Split-Path -Parent $path)) }
    }.GetNewClosure()

    $openLogAction = {
        if (-not $state.LogPath -or -not (Test-Path -LiteralPath $state.LogPath -PathType Leaf)) { throw '本次任务日志不存在。' }
        $path = [string]$state.LogPath
        Start-Process -FilePath notepad.exe -ArgumentList @("`"$path`"") -ErrorAction Stop
    }.GetNewClosure()

    $ui.CommandBox.Add_SelectionChanged({ & $updateCommandUiAction }.GetNewClosure())
    $ui.AnalyzeInputModeBox.Add_SelectionChanged({ & $updateAnalyzeInputModeAction }.GetNewClosure())

    Register-CkButtonAction -Button $ui.ChooseAnalyzeParentButton -Action { & $chooseFolderAction $ui.AnalyzeParentBox '选择包含服装 resources 的父目录' $false }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.AddAnalyzeResourceButton -Action { & $appendResourceAction $ui.AnalyzeResourcesBox '添加一个 FiveM 服装 resource 目录' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ClearAnalyzeResourcesButton -Action { $ui.AnalyzeResourcesBox.Clear() }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseAnalyzeGeneratedRootButton -Action { & $chooseFolderAction $ui.AnalyzeGeneratedRootBox '选择生成 resource 的父目录' $true }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseAnalyzePlanButton -Action { & $chooseSaveFileAction $ui.AnalyzePlanBox 'JSON 方案 (*.json)|*.json|所有文件 (*.*)|*.*' '保存打包方案' '.json' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseBuildPlanButton -Action { & $chooseOpenFileAction $ui.BuildPlanBox 'JSON 方案 (*.json)|*.json|所有文件 (*.*)|*.*' '选择打包方案' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseBuildOutputButton -Action { & $chooseFolderAction $ui.BuildOutputBox '选择预览输出目录' $true }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseApplyPlanButton -Action { & $chooseOpenFileAction $ui.ApplyPlanBox 'JSON 方案 (*.json)|*.json|所有文件 (*.*)|*.*' '选择要应用的方案' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseApplyBackupButton -Action { & $chooseFolderAction $ui.ApplyBackupBox '选择备份根目录' $true }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseRestoreManifestButton -Action { & $chooseOpenFileAction $ui.RestoreManifestBox '备份清单 (backup-manifest.json)|backup-manifest.json|JSON 文件 (*.json)|*.json' '选择备份清单' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseValidatePlanButton -Action { & $chooseOpenFileAction $ui.ValidatePlanBox 'JSON 方案 (*.json)|*.json|所有文件 (*.*)|*.*' '选择要校验的方案' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseValidateParentButton -Action { & $chooseFolderAction $ui.ValidateParentBox '选择包含服装 resources 的父目录' $false }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.AddValidateResourceButton -Action { & $appendResourceAction $ui.ValidateResourcesBox '添加一个要校验的 resource 目录' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ClearValidateResourcesButton -Action { $ui.ValidateResourcesBox.Clear() }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseValidateGeneratedRootButton -Action { & $chooseFolderAction $ui.ValidateGeneratedRootBox '选择生成 resource 的父目录' $true }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseReportPlanButton -Action { & $chooseOpenFileAction $ui.ReportPlanBox 'JSON 方案 (*.json)|*.json|所有文件 (*.*)|*.*' '选择报告方案' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseReportOutputButton -Action { & $chooseSaveFileAction $ui.ReportOutputBox '文本报告 (*.txt)|*.txt|所有文件 (*.*)|*.*' '保存打包报告' '.txt' }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ClearReportOutputButton -Action { $ui.ReportOutputBox.Clear() }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.ChooseExportFolderButton -Action { & $chooseFolderAction $ui.ExportFolderBox '选择包含 YMT 的目录' $false }.GetNewClosure() -OnError $showPageError
    Register-CkButtonAction -Button $ui.StartButton -Action $startAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.StopButton -Action $stopAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenResultButton -Action $openResultAction -OnError $showPageError
    Register-CkButtonAction -Button $ui.OpenLogButton -Action $openLogAction -OnError $showPageError

    & $updateAnalyzeInputModeAction
    & $updateCommandUiAction
    & $updateEnvironmentAction
    return [pscustomobject]@{
        Id = 'clothing-repacker'
        Title = '衣服资源打包'
        Icon = '♜'
        Root = $root
        Activate = $updateEnvironmentAction
    }
}
