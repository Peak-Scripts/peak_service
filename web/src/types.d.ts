interface Window {
  invokeNuiCallback: (eventName: string, data: any) => void;
}

interface CommunityServiceData {
  admin: string;
  remainingTasks: number;
  reason: string;
}
