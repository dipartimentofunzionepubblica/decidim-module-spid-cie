class SecretsModifier
  def initialize(filepath, tenant_name, type)
    @filepath = filepath
    @tenant_name = tenant_name
    @type = type
  end

  def modify
    self.inside_config = false
    self.inside_omniauth = false
    self.config_branch = nil
    @final = ""

    @empty_line_count = 0
    File.readlines(filepath).each do |line|
      if line.match?(/^$/)
        @empty_line_count += 1
        next
      else
        handle_line line
        insert_empty_lines
      end

      @final += line
    end
    insert_empty_lines

    @final
  end

  private

  attr_accessor :filepath, :empty_line_count, :inside_config, :inside_omniauth, :config_branch, :tenant_name, :type

  def handle_line(line)
    if inside_config && line.match?(/^  omniauth:/)
      self.inside_omniauth = true
    elsif inside_omniauth && (line.match?(/^(  )?[a-z]+/) || line.match?(/^#.*/))
      type == :spid ? inject_spid_config : inject_cie_config
      self.inside_omniauth = false
    end

    return unless line.match?(/^[a-z]+/)

    # A new root configuration block starts
    self.inside_config = false
    self.inside_omniauth = false

    branch = line[/^(default):/, 1]
    if branch
      self.inside_config = true
      self.config_branch = branch.to_sym
    end
  end

  def insert_empty_lines
    @final += "\n" * empty_line_count
    @empty_line_count = 0
  end

  def inject_spid_config
    @final += "    spid:\n"
    case config_branch
    when :development, :test
      @final += "      enabled: true\n"
    else
      @final += "      enabled: false\n"
    end
    @final += "      tenant_name: #{tenant_name}\n"
    @final += "      size: l # available options: s, m, l, xl\n"
  end

  def inject_cie_config
    @final += "    cie:\n"
    case config_branch
    when :development, :test
      @final += "      enabled: true\n"
    else
      @final += "      enabled: false\n"
    end
    @final += "      tenant_name: #{tenant_name}\n"
    @final += "      size: l # available options: s, m, l, xl\n"
  end
end