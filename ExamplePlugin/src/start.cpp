#include "start.hpp"

#include <imgui.h>
#include <log/Log.hpp>
#include <nlohmann/json.hpp>

using namespace sim;


void ExampleComponent::solder(std::span<PinState* const> pins_write, std::span<const PinState* const> pins_read, const std::vector<std::string>& pinNames)
{
	// stores pin pointers for later access
	Circuit::solder(pins_write, pins_read, pinNames);
}

bool ExampleComponent::drawWindow()
{
	return ImGui::Checkbox("Break on HIGH", &m_breakpoint_active);
}

void ExampleComponent::save(nlohmann::json& j) const
{
	j["state"] = m_breakpoint_active;
}

void ExampleComponent::load(const nlohmann::json& j)
{
	m_breakpoint_active = j.value("state", false);
}

bool ExampleComponent::step(bool ignoreBreakpoint)
{
	// forward the input to the output
	// e.g. HIGH to HIGH, DOWN to DOWN, Z to Z
	PinState inState = readPin(IN);
	writePin(OUT, inState);

	// equivalent to:
	// *m_pinsWrite[OUT] = *m_pinsRead[IN];

	// this forwards only bool (bit)
	// e.g. HIGH to HIGH, UP to HIGH, everything else to LOW
	//writeBits(OUT, 1, (bool)readPin(IN));


	if (inState && m_breakpoint_active && !ignoreBreakpoint)
		return false; // breakpoint hit

	return true;
}


void ExampleFoundry::initialize()
{
	ND_INFO("Initializing Example foundry...");
}
