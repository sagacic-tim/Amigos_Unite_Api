
Rails.application.configure do
  config.content_security_policy do |p|
    p.default_src :self
    p.script_src  :self
    p.style_src   :self
    p.img_src     :self, :data
    p.connect_src :self, 'https://localhost:3001' # API
    p.frame_ancestors :none
    p.base_uri :self
  end
  config.content_security_policy_report_only = false
end
