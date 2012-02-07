# Patch Sinatra::Response#finish to not calculate Content-Length unless
# all members of an array are strings
class Sinatra::Response
  def finish
    if status.to_i / 100 == 1
      headers.delete "Content-Length"
      headers.delete "Content-Type"
    elsif RDF::Query::Solutions === body
      # Don't calculate content-length here
    elsif Array === body and not [204, 304].include?(status.to_i)
      headers["Content-Length"] = body.inject(0) { |l, p| l + Rack::Utils.bytesize(p) }.to_s
    end

    # Rack::Response#finish sometimes returns self as response body. We don't want that.
    status, headers, result = super
    result = body if result == self
    [status, headers, result]
  end
end