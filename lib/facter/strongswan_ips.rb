Facter.add("strongswan_ips") do
  setcode do
    bin = ['/usr/sbin/ipsec', '/usr/sbin/strongswan'].find do |f|
      File.exists?(f)
    end
    return unless bin
    output = Facter::Util::Resolution.exec(
        "#{bin} statusall | grep -E '^  [0-9a-f]' | sort | uniq")
            .to_s.split("\n").collect(&:strip)
    output.join(',') unless output.empty?
  end
end
