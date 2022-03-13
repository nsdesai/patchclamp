// MulticlampControl.cpp : Control of Multiclamp 700A/700B for automated patch clamp system.
//
// This Visual Studio project makes use of the API that Molecular Devices provides for Multiclamp amplifiers. 
// When one installs the Multiclamp Commander, the requisite files are found in the folder "3rd Party Support". 
//
// The project is a 32-bit Windows Console Application. Note well: if you change anything and wish to
// re-compile, make sure the project is still 32 bit and not 64 bit (i.e., make sure the field at the top
// of the Visual Studio pane is "x86" and not "x64"). The Molecular Devices libraries on which this
// project depends have not been updated since 2004, and so 32 bit it is for the foreseeable future. 
// Also, make sure that the MFC property is set to be "Use MFC as shared DLL" 
// (Project >> MulticlampControl Properties ... >> Configuration Properties >>
// General >> Use of MFC >> Use MFC as shared DLL).
//
// When calling MulticlampControl, one should pass 4-8 arguments. The first is an integer specifying
// the type of amplifier (0 = 700A and 1 = 700B). The second is either the amplifier's COM port (700A) or
// its serial number (700B). The third is the channel number (1 or 2). The fourth is an integer specifying 
// what action to take, as follows:
// 0:		put the Multiclamp into current clamp without making other changes
// 1:		put the Multiclamp into voltage clamp without making other changes
// 2: 		put the Multiclamp into current clamp with a gain specified by the fifth argument, bridge
//				balance set to the resistance in MOhms specified by the sixth argument, pipette
//				capacitance neutralization in pF specified by the seventh argument, and holding currrent
//				in pA specified by the eighth argument. If the bridge or capacitance neutralization numbers
//				are greater than or equal to 1000, they are left unchanged (for cases where we just want to change 
//				the gain or the holding current, but nothing else)
// 3:		put the Multiclamp into voltage clamp with a gain specified by the fifth argument and 
//				a holding potential in mV specified by the sixth argument
// 4:		run the amplifier's auto fast and slow pipette capacitance compensation (voltage clamp)
// 5:		zero the pipette offset
// 6:		put the Multiclamp into (I=0) mode with a gain given by the fifth argument
// 7:		get information about the state of the Multiclamp amplifier
// 8:		turn the seal test (voltage clamp) or tuning (current clamp) on or off
//
// Created 05/16/16 by Niraj S. Desai (NSD)
// Last modified 06/12/19 (NSD)

// To do: 	(1) Put the command that destroys the handle in a separate function and make sure any failures 
// 			invoke that function before returning
//			(2) Add comments (cout) that describe the error in case of failure

#include "stdafx.h"
#include <iostream>
#include <afxwin.h> 
#include "AxMultiClampMsg.h" 
using namespace std;


//============================================================================ 
// FUNCTION: main 
//
int main(int argc, char *argv[])
{

	// remember that the function name is always the first argument
	if (argc < 5) {
		cout << "You must enter at least four arguments. " << endl;
		return 0;
	}

	// create DLL handle 
	int nError = MCCMSG_ERROR_NOERROR;
	HMCCMSG hMCCmsg = MCCMSG_CreateObject(&nError);
	if (!hMCCmsg)
	{
		return 0;
	}


	// find the first MultiClamp    
	char szError[256] = "";
	char szSerialNum[16] = ""; // Serial number of MultiClamp 700B    
	UINT uModel = 0;  // Identifies MultiClamp 700A or 700B model 
	UINT uCOMPortID = 0;  // COM port ID of MultiClamp 700A (1-16) 
	UINT uDeviceID = 0;  // Device ID of MultiClamp 700A (1-8)    
	UINT uChannelID = 0;  // Headstage channel ID    
	if (!MCCMSG_FindFirstMultiClamp(hMCCmsg, &uModel, szSerialNum,
		sizeof(szSerialNum), &uCOMPortID,
		&uDeviceID, &uChannelID, &nError))
	{
		return 0;
	}


	bool foundAmplifier = false;
	char* context = NULL;
	char* serialNo700B;
	serialNo700B = strtok_s(argv[2], " ", &context);


	// find the second MultiClamp, third MultiClamp, ... etc 
	while(1) {
		// check to see whether we have found the specified amplifier
		// for 700B amplifiers, compare the serial numbers
		// for 700A amplifiers, compare the COM ports
		if (atoi(argv[1]) == uModel) {
			if (!strcmp(serialNo700B, szSerialNum) || atoi(argv[2]) == uCOMPortID) {
				foundAmplifier = true;
				break;
			}
		}
		// create string with device info    
		char szDeviceInfo[256] = "";    
		switch( uModel )    
		{       
			case MCCMSG_HW_TYPE_MC700A:          
				sprintf_s(szDeviceInfo, "MultiClamp 700A open on COM port %d, device ID %d. Headstage channel %d connected.",uCOMPortID, uDeviceID, uChannelID);
				break;       
			case MCCMSG_HW_TYPE_MC700B:          
				sprintf_s(szDeviceInfo, "MultiClamp 700B open on USB port with serial number %s. Headstage channel %d connected.",szSerialNum, uChannelID);    
		}     
		// find the next MultiClamp    
		if( !MCCMSG_FindNextMultiClamp(hMCCmsg, &uModel, szSerialNum,sizeof(szSerialNum), &uCOMPortID,&uDeviceID, &uChannelID, &nError) )    
		{       
			break;    
		} 
	}   

	if (!foundAmplifier) {
		cout << "Could not find amplifier. Please check model type and ID. " << endl;
		return 0;
	}
	
	uChannelID = atoi(argv[3]); // specify which channel to select

	// select this MultiClamp 
	if (!MCCMSG_SelectMultiClamp(hMCCmsg, uModel, szSerialNum,
		uCOMPortID, uDeviceID, uChannelID, &nError))
	{
		return 0;
	}

	BOOL bEnable = true;
	double dGain = 1;
	double dResist = 0; // Ohms 
	double dCap = 0; // F
	double dHolding = 0; // V or A
	double dTest = 0; // 0 (test signal off) or 1 (test signal on)
	UINT uMode = 0; 
	BOOL bEnable_pipette_neutralization = false;
	BOOL bEnable_bridge_balance = false;

	switch (atoi(argv[4]))
	{

		case 0: // switch to current clamp

			if (!MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_ICLAMP, &nError))
			{
				return 0;
			}

			break;

		case 1: // switch to voltage clamp

			if (!MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_VCLAMP, &nError))
			{
				return 0;
			}

			break;

		case 2: // switch to current clamp with specified gain, bridge balance, cap neutralization, holding current

			dGain = atof(argv[5]);
			dResist = atof(argv[6]) * 1e6; // Ohms
			dCap = atof(argv[7]) * 1e-12; // F
			dHolding = atof(argv[8]) * 1e-12; // A
			
			// switch to current clamp
			// for future reference, MCCMSG_MODE_ICLAMPZERO is for I=0 mode 
			if (!MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_ICLAMP, &nError))
			{
				return 0;
			}

			// set the gain
			if (!MCCMSG_SetPrimarySignalGain(hMCCmsg, dGain, &nError)) {
				return 0;
			}		

			if (dResist < 1e9) {
				// set the bridge balance resistance 
				if (!MCCMSG_SetBridgeBalResist(hMCCmsg, dResist, &nError))
				{
					return 0;
				}

				// enable bridge balance
				if (!MCCMSG_SetBridgeBalEnable(hMCCmsg, bEnable, &nError))
				{
					return 0;
				}
			}

			if (dCap < 1e-9) {
				// set pipette neutralization capacitance 
				if (!MCCMSG_SetNeutralizationCap(hMCCmsg, dCap, &nError))
				{
					return 0;
				}

				// enable pipette capacitance neutralization 
				if (!MCCMSG_SetNeutralizationEnable(hMCCmsg, bEnable, &nError))
				{
					return 0;
				}
			}

			// set the holding current 
			if (dHolding < 1e-9) {
				if (!MCCMSG_SetHolding(hMCCmsg, dHolding, &nError))
				{
					return 0;
				}

				// set the holding enable state 
				if (atoi(argv[8]) == 0) { bEnable = false; };
				if (!MCCMSG_SetHoldingEnable(hMCCmsg, bEnable, &nError))
				{
					return 0;
				}
			}


		 	break;

		 case 3: 	// switch to voltage clamp mode with specified gain and holding potential

			dGain = atof(argv[5]);
			dHolding = atof(argv[6]) * 1e-3; // mV

			// switch to voltage clamp
			if (!MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_VCLAMP, &nError))
			{
				return 0;
			}

			// set the gain
			if (!MCCMSG_SetPrimarySignalGain(hMCCmsg, dGain, &nError)) {
				return 0;
			}

			// set the holding level 
			if( !MCCMSG_SetHolding(hMCCmsg, dHolding, &nError) ) 
			{    
				return 0;
			}

			// set the holding enable state 
			if (atoi(argv[6]) == 0) { bEnable = false; };
			if( !MCCMSG_SetHoldingEnable(hMCCmsg, bEnable, &nError) ) 
			{    
				return 0;    
			}  

			break;

		case 4:  	// in voltage clamp, use the amplifier's auto pipette capacitance compensation

			// execute auto fast compensation 
			if (!MCCMSG_AutoFastComp(hMCCmsg, &nError))
			{
				return 0;
			}

			// execute auto slow compensation 
			if (!MCCMSG_AutoSlowComp(hMCCmsg, &nError)) 
			{
				return 0;
			}

			break;

		case 5:		// zero the pipette offset automatically

			// execute auto pipette offset 
			if( !MCCMSG_AutoPipetteOffset(hMCCmsg, &nError) ) 
			{    
				return 0;
			}   

			break;


		case 6:		// put the amplifier in I=0 mode

			dGain = atof(argv[5]);

			// switch to I=0 
			if (!MCCMSG_SetMode(hMCCmsg, MCCMSG_MODE_ICLAMPZERO, &nError))
			{
				return 0;
			}

			// set the gain
			if (!MCCMSG_SetPrimarySignalGain(hMCCmsg, dGain, &nError)) {
				return 0;
			}

			break;

		case 7:		// get information on amplifier state

			//  amplifier mode (uMode = 0 V-clamp, uMode = 1 I-clamp, uMode = 2 I-zero)
			if( !MCCMSG_GetMode(hMCCmsg, &uMode, &nError) )
			{    
				return 0;
			}

			// gain
			if (!MCCMSG_GetPrimarySignalGain(hMCCmsg, &dGain, &nError))
			{
				return 0;
			}


			// holding current/potential enable
			if (!MCCMSG_GetHoldingEnable(hMCCmsg, &bEnable, &nError))
			{
				return 0;
			}

			// holding current/potential value
			if (!MCCMSG_GetHolding(hMCCmsg, &dHolding, &nError))
			{
				return 0;
			}

			// pipette neutralization enable (current clamp)
			if (!MCCMSG_GetNeutralizationEnable(hMCCmsg, &bEnable_pipette_neutralization, &nError))
			{
				return 0;
			}

			// pipette neutralization value (current clamp
			if (!MCCMSG_GetNeutralizationCap(hMCCmsg, &dCap, &nError))
			{
				return 0;
			}

			// bridge balance enable (current clamp)
			if (!MCCMSG_GetBridgeBalEnable(hMCCmsg, &bEnable_bridge_balance, &nError))
			{
				return 0;
			}

			// bridge balance value (current clamp)
			if (!MCCMSG_GetBridgeBalResist(hMCCmsg, &dResist, &nError))
			{
				return 0;
			}

			cout << "mode_gain_holdingEnable_holding_capEnable_cap_bridgeEnable_bridge," << uMode << "," << dGain << "," << bEnable << "," << dHolding << "," << bEnable_pipette_neutralization << "," << dCap << "," << bEnable_bridge_balance << "," << dResist <<  endl;

			break;

		case 8:			// turn the seal test (v-clamp) or tuning (i-clamp) on or off

			dTest = atof(argv[5]);
			
			if (dTest < 1e-1) { bEnable = false; }
			
			if (!MCCMSG_SetTestSignalEnable(hMCCmsg, bEnable, &nError))
				{
					return 0;
			}


		default:

			cout << "No command executed. " << endl;

	}

	// destroy DLL handle
	MCCMSG_DestroyObject(hMCCmsg);
	hMCCmsg = NULL;

	return 1;
}
