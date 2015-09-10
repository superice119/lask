
require 'std'

local ssl = require 'ssl'
local tasklet = require 'tasklet.channel.sslstream'
local log = require 'log'

require 'tasklet.channel.stream'

local MULTIPLE = tonumber(arg[1]) or 1000000
local IP = arg[2] or '127.0.0.1'
local PORT = tonumber(arg[3]) or 60001

local ctx = ssl.context.new('sslv23')

tasklet.sslstream_channel.ctx = ctx

io.stdout:setvbuf('no')

tasklet.start_task(function ()
	local ch_stdin = tasklet.create_stream_channel(0)
	local ch = tasklet.create_sslstream_channel()
	local buf = buffer.new()
	
	if ch:connect(IP, PORT) ~= 0 then
		log.fatal('server not started')
	end
	
	while true do 
		local line = ch_stdin:read()
		if not line then
			break
		end
		
		local nreq = #line
		if nreq > 0 then
			local nresp = nreq * MULTIPLE
			local left = nresp
			ch:write(buf:rewind():putstr(line, '\r\n'))
			log.info(string.format('send %d bytes, expecting %d bytes', nreq, nresp))
			
			while left > 0 do
				local rd, err = ch:read(left)
				if not rd then
					dump(ch)
					log.fatal('ch:read() failed: errno -> ', errno.strerror(err))
				end
				
				left = left - #rd
				io.stdout:write(string.format('\r(%d/%d)', nresp - left, nresp))
			end
			print('')
			log.info('succeed')
		end
	end
	ch:close()
	tasklet.quit()
end)

tasklet.loop()
