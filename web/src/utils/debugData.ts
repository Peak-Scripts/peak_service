import { isEnvBrowser } from "./misc";

// More flexible event interface
interface DebugEvent {
  action: string;
  data: any;
}

/**
 * Emulates dispatching an event using SendNuiMessage in the lua scripts.
 * This is used when developing in browser
 *
 * @param events - The events you want to cover
 * @param timer - How long until it should trigger (ms)
 */
export const debugData = (events: DebugEvent[], timer = 1000): void => {
  // Only dispatch in browser development mode
  if (import.meta.env.MODE === "development" && isEnvBrowser()) {
    console.log('[debugData] Dispatching debug events:', events);
    
    for (const event of events) {
      setTimeout(() => {
        try {
          window.dispatchEvent(
            new MessageEvent("message", {
              data: {
                action: event.action,
                data: event.data,
              },
            })
          );
          console.log(`[debugData] Dispatched event: ${event.action}`, event.data);
        } catch (error) {
          console.error('[debugData] Error dispatching event:', error);
        }
      }, timer);
    }
  }
};
