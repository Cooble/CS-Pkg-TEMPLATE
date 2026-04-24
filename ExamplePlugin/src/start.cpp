#include "start.hpp"

#include <imgui.h>
#include <log/Log.hpp>
#include <nlohmann/json.hpp>


EXPORT_CIRCUIT_FOUNDRY(ExampleFoundry);

using namespace sim;


void ExampleForwarder::solder(std::span<PinState* const> pins_write, std::span<const PinState* const> pins_read, double freq)
{
	// stores pin pointers for later access
	Circuit::solder(pins_write, pins_read,  freq);
}

bool ExampleForwarder::drawWindow()
{
	return ImGui::Checkbox("Break on HIGH", &m_breakpoint_active);
}

void ExampleForwarder::save(nlohmann::json& j) const
{
	j["state"] = m_breakpoint_active;
}

void ExampleForwarder::load(const nlohmann::json& j)
{
	m_breakpoint_active = j.value("state", false);
}

bool ExampleForwarder::step(bool ignoreBreakpoint)
{
	// forward the input to the output
	// e.g. HIGH to HIGH, DOWN to DOWN, Z to Z
	PinState inState = readPin(IN);
	m_state = inState;

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
