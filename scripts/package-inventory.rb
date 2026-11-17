require 'json'
require 'open3'
require 'find'

def brew(*args)
  output, error, status = Open3.capture3('brew', *args)
  abort "Homebrew inventory failed for #{args.first}: #{error.lines.first}" unless status.success?
  output
end

manifest = File.read(ARGV.fetch(0))
formulae = manifest.scan(/^brew\s+"([^"]+)"/).flatten
casks = manifest.scan(/^cask\s+"([^"]+)"/).flatten
installed = brew('list', '--formula', '--full-name').lines.map(&:strip)
direct = brew('info', '--formula', '--installed', '--json=v2')
  .then { |output| JSON.parse(output).fetch('formulae') }
  .select { |formula| formula.fetch('installed').any? { |receipt| receipt['installed_on_request'] } }
  .map { |formula| formula.fetch('full_name') }
metadata = JSON.parse(brew('info', '--cask', '--installed', '--json=v2')).fetch('casks')

def report(label, values)
  puts "#{label}: #{values.empty? ? 'none' : values.sort.join(', ')}"
end

report('Missing required formulae', formulae - installed)
report('Other formulae installed on request', direct - formulae)
report('Required casks without a Homebrew receipt', casks - metadata.map { |cask| cask.fetch('token') })
report('Other installed casks', metadata.map { |cask| cask.fetch('token') } - casks)

artifacts = {}
metadata.each do |cask|
  paths = cask.fetch('artifacts').map do |artifact|
    next unless artifact['app']
    source, options = artifact['app']
    target = (options || {}).fetch('target', source)
    File.expand_path(target, cask['appdir'] || '/Applications')
  end.compact
  puts "Cask without a direct app artifact: #{cask.fetch('token')}" if paths.empty?
  paths.each { |path| artifacts[path] = cask.fetch('token') }
end

Find.find('/Applications').sort.each do |path|
  # Embedded app bundles are usually components of the enclosing app.
  next unless path.end_with?('.app') && File.directory?(path)
  relative = path.delete_prefix('/Applications/')
  next if relative.split('/')[0...-1].any? { |part| part.end_with?('.app') }
  if artifacts.key?(path)
    puts "Homebrew app: #{relative} (#{artifacts.delete(path)})"
  elsif relative.start_with?('Utilities/')
    puts "Review possible helper: #{relative}"
  else
    puts "No direct cask artifact match: #{relative}"
  end
end
artifacts.sort.each { |_, token| puts "Cask app target not seen under /Applications: #{token}" }
