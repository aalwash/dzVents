local _ = require 'lodash'

package.path = package.path .. ";../?.lua"

local LOG_INFO = 2
local LOG_DEBUG = 3
local LOG_ERROR = 1

describe('device', function()
	local Device
	local commandArray = {}
	local cmd
	local device

	local domoticz = {
		sendCommand = function(command, value)
			table.insert(commandArray, {[command] = value})
			return commandArray[#commandArray], command, value
		end
	}

	setup(function()
		_G.logLevel = 1
		_G.log = function()	end
		Device = require('Device')

	end)

	teardown(function()
		Device = nil
	end)

	before_each(function()
		device = Device(domoticz, 'myDevice', 'On', true)
		device.id = 100
	end)

	after_each(function()
		device = nil
		commandArray = {}

	end)

	it('should instantiate', function()
		assert.is_not_nil(device)
	end)

	it('should have a name', function()
		assert.is_same('myDevice', device.name)
	end)

	it('should be marked as changed when the device was changed', function()
		assert.is_true(device.changed)
	end)

	it('should not be marked as changed when the device was not changed', function()
		local device = Device(domoticz, 'myDevice', 'On', false)
		assert.is_false(device.changed)
	end)

	it('should not have a state when it doesnt have one', function()
		local device = Device(domoticz, 'myDevice', nil, false)
		assert.is_nil(device.state)
	end)

	it('should extract level', function()
		local device = Device(domoticz, 'myDevice', 'Set Level 55%', false)
		assert.is_same('On', device.state)
		assert.is_number(device.level)
		assert.is_same(55, device.level)
	end)

	it('should have a bState when possible', function()
		local device = Device(domoticz, 'myDevice', 'Set Level 55%', false)
		assert.is_true(device.bState)

		device = Device(domoticz, 'myDevice', '', false)
		assert.is_false(device.bState)


		device = Device(domoticz, 'myDevice', 'On', false)
		assert.is_true(device.bState)

		local states = device._States

		_.forEach(states, function(value, key)
			--			print(key, value)
			device = Device(domoticz, 'myDevice', key, false)
			if (value.b) then
				assert.is_true(device.bState)
			else
				assert.is_false(device.bState)
			end
		end)

	end)

	it('should set the state', function()
		local cmd = device.setState('Off')
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Off"}, cmd._latest)
	end)

	it('should switch on', function()
		device = Device(domoticz, 'myDevice', 'Off', false)

		local cmd = device.switchOn()
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="On"}, cmd._latest)
	end)

	it('should switch off', function()
		device = Device(domoticz, 'myDevice', 'On', false)

		local cmd = device.switchOff()
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Off"}, cmd._latest)
	end)

	it('should close', function()
		device = Device(domoticz, 'myDevice', 'Open', false)

		local cmd = device.close()
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Closed"}, cmd._latest)
	end)

	it('should open', function()
		device = Device(domoticz, 'myDevice', 'Closed', false)

		local cmd = device.open()
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Open"}, cmd._latest)
	end)

	it('should stop', function()
		device = Device(domoticz, 'myDevice', 'Closed', false)

		local cmd = device.stop()
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Stop"}, cmd._latest)
	end)

	it('should dim to a level', function()
		device = Device(domoticz, 'myDevice', 'On', false)

		local cmd = device.dimTo(5)
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Set Level 5"}, cmd._latest)
	end)

	it('should switch a selector', function()
		device = Device(domoticz, 'myDevice', 'On', false)

		local cmd = device.switchSelector(15)
		assert.is_table(cmd)
		assert.is_same({["myDevice"]="Set Level 15"}, cmd._latest)
	end)

	describe('Updating', function()
		it('should send generic update commands', function()
			device.update(1,2,3,4,5)
			assert.is_same({{["UpdateDevice"]="100|1|2|3|4|5"}}, commandArray)
		end)

		it('should update temperature', function()
			device.updateTemperature(10)
			assert.is_same({{["UpdateDevice"]="100|0|10"}}, commandArray)
		end)

		it('should update humidity', function()
			device.updateHumidity(10, 1)
			assert.is_same({{["UpdateDevice"]="100|10|1"}}, commandArray)
		end)

		it('should update barometer', function()
			device.updateBarometer(10, 1)
			assert.is_same({{["UpdateDevice"]="100|0|10;1"}}, commandArray)
		end)

		it('should update temperature and humidity', function()
			device.updateTempHum(10, 20, 2)
			assert.is_same({{["UpdateDevice"]="100|0|10;20;2"}}, commandArray)
		end)

		it('should update temperature and humidity and barometer', function()
			device.updateTempHumBaro(10, 20, 2, 5,7)
			assert.is_same({{["UpdateDevice"]="100|0|10;20;2;5;7"}}, commandArray)
		end)

		it('should update rain', function()
			device.updateRain(10, 20)
			assert.is_same({{["UpdateDevice"]="100|0|10;20"}}, commandArray)
		end)

		it('should update wind', function()
			device.updateWind(1,2,3,4,5,6)
			assert.is_same({{["UpdateDevice"]="100|0|1;2;3;4;5;6"}}, commandArray)
		end)

		it('should update uv', function()
			device.updateUV(12)
			assert.is_same({{["UpdateDevice"]="100|0|12;0"}}, commandArray)
		end)

		it('should update counter', function()
			device.updateCounter(22)
			assert.is_same({{["UpdateDevice"]="100|22"}}, commandArray)
		end)

		it('should update electricity', function()
			device.updateElectricity(220, 1000)
			assert.is_same({{["UpdateDevice"]="100|0|220;1000"}}, commandArray)
		end)

		it('should update P1', function()
			device.updateP1(1,2,3,4,5,6)
			assert.is_same({{["UpdateDevice"]="100|0|1;2;3;4;5;6"}}, commandArray)
		end)

		it('should update air quality', function()
			device.updateAirQuality(44)
			assert.is_same({{["UpdateDevice"]="100|44"}}, commandArray)
		end)

		it('should update pressure', function()
			device.updatePressure(1200)
			assert.is_same({{["UpdateDevice"]="100|0|1200"}}, commandArray)
		end)

		it('should update percentage', function()
			device.updatePercentage(88)
			assert.is_same({{["UpdateDevice"]="100|0|88"}}, commandArray)
		end)

		it('should update gas', function()
			device.updateGas(880)
			assert.is_same({{["UpdateDevice"]="100|0|880"}}, commandArray)
		end)

		it('should update lux', function()
			device.updateLux(333)
			assert.is_same({{["UpdateDevice"]="100|333"}}, commandArray)
		end)

		it('should update voltage', function()
			device.updateVoltage(120)
			assert.is_same({{["UpdateDevice"]="100|0|120"}}, commandArray)
		end)

		it('should update text', function()
			device.updateText('foo')
			assert.is_same({{["UpdateDevice"]="100|0|foo"}}, commandArray)
		end)

		it('should update alert sensor', function()
			device.updateAlertSensor(45, 'o dear')
			assert.is_same({{["UpdateDevice"]="100|45|o dear"}}, commandArray)
		end)

		it('should update distance', function()
			device.updateDistance(67)
			assert.is_same({{["UpdateDevice"]="100|0|67"}}, commandArray)
		end)

	end)

	it('should mark an attribute as changed', function()
		device.setAttributeChanged('temperature')
		assert.is_true(device.attributeChanged('temperature'))
	end)

	it('should add an attribute', function()
		device.addAttribute('temperature', 20)
		assert.is_same(device.temperature, 20)
	end)

	it('should toggle a switch', function()
		local cmd = device.toggleSwitch()
		assert.is_same({["myDevice"]="Off"}, cmd._latest)

		device = Device(domoticz, 'myDevice', 'Off', false)
		cmd = device.toggleSwitch()
		assert.is_same({["myDevice"]="On"}, cmd._latest)

		device = Device(domoticz, 'myDevice', 'Playing', false)
		cmd = device.toggleSwitch()
		assert.is_same({["myDevice"]="Pause"}, cmd._latest)

		device = Device(domoticz, 'myDevice', 'Chime', false)
		cmd = device.toggleSwitch() -- shouldn't do anything
		assert.is_nil(cmd)
	end)
end)
