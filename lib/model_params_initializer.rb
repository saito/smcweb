module ModelParamsInitializer

  # 全て文字列のままプロパティに設定します。
  def params_initialize(params, target, keys)
    @errors = []
    return if target.nil?
    return if params.nil?
    return if params[target].nil?
    input = params[target]

    keys.each do |k|
      self.send(k.to_s + "=", input[k]) unless input[k].nil?
    end
  end
  
end