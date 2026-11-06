import { Mastra } from '@mastra/core/mastra';
import { LibSQLStore } from '@mastra/libsql';
import { STUDIO_DIR } from './factory/loader';
import { factoryAgents } from './agents';
import { deliveryWorkflow } from './workflows/delivery';

export const mastra = new Mastra({
  agents: factoryAgents,
  workflows: { deliveryWorkflow },
  storage: new LibSQLStore({ id: 'factory-storage', url: `file:${STUDIO_DIR}/factory.db` }),
});
