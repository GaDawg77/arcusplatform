/*
 * Copyright 2019 Arcus Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.iris.platform.subsystem.pairing.handler;

import com.google.inject.Singleton;
import com.iris.common.subsystem.SubsystemContext;
import com.iris.messages.MessageBody;
import com.iris.messages.capability.PairingSubsystemCapability.StopSearchingRequest;
import com.iris.messages.capability.PairingSubsystemCapability.StopSearchingResponse;
import com.iris.messages.listener.annotation.Request;
import com.iris.messages.model.subs.PairingSubsystemModel;
import com.iris.platform.subsystem.pairing.state.PairingStateMachine;

@Singleton
public class StopSearchingHandler {

	
	@Request(StopSearchingRequest.NAME)
	public MessageBody stopSearching(SubsystemContext<PairingSubsystemModel> context) {
		PairingStateMachine.get(context).stopPairing();
		return StopSearchingResponse.instance();
	}
}
