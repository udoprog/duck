require 'duck/chroot_utils'
require 'duck/logging'

module Duck
  class Pack
    include ChrootUtils
    include Logging

    def initialize(options)
      @target = options[:target]
      @original_target = @target
      @target_min = "#{@target}.min"
      @chroot_env = options[:env]
      @initrd = options[:initrd]
      @no_minimize = options[:no_minimize]
      @keep_minimized = options[:keep_minimized]
    end

    def minimize_target
      log.info "Minimizing Target"
      spawn ['rm', '-rf', @target_min] if File.directory? @target_min
      spawn ['cp', '-a', @target, @target_min]

      @target = @target_min

      in_apt_get "clean"
      in_shell "rm -rf /var/lib/{apt,dpkg} /usr/share/{doc,man} /var/cache"
    end

    def execute
      minimize_target unless @no_minimize

      Dir.chdir @target
      log.info "Packing #{@target} into #{@initrd}"
      shell "find . | cpio -o -H newc | lzma -9 > #{@initrd}"

      spawn ['rm', '-r', '-f', @target] unless @keep_minimized

      log.info "Done building initramfs image: #{@initrd}"
    end
  end
end
