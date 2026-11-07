@IsTest
private class TechLarAgentControllerTest {
    @IsTest
    static void sendsTheMessageAndPreservesTheAgentSession() {
        TechLarAgentController.invoker = new FakeAgentInvoker();

        Test.startTest();
        TechLarAgentController.AgentReply reply = TechLarAgentController.sendMessage(
            'Repor as lojas que precisam',
            'existing-session'
        );
        Test.stopTest();

        System.assertEquals('Resposta real do agente', reply.message);
        System.assertEquals('next-session', reply.sessionId);
        System.assertEquals(0, reply.transfers.size());
    }

    @IsTest
    static void rejectsBlankMessages() {
        try {
            TechLarAgentController.sendMessage('  ', null);
            System.assert(false, 'A mensagem vazia deveria ser recusada.');
        } catch (AuraHandledException handledError) {
            System.assert(handledError.getMessage().contains('Digite uma mensagem'));
        }
    }

    private class FakeAgentInvoker extends TechLarAgentController.AgentInvoker {
        public override TechLarAgentController.AgentReply send(String userMessage, String sessionId) {
            System.assertEquals('Repor as lojas que precisam', userMessage);
            System.assertEquals('existing-session', sessionId);
            TechLarAgentController.AgentReply reply = new TechLarAgentController.AgentReply();
            reply.message = 'Resposta real do agente';
            reply.sessionId = 'next-session';
            return reply;
        }
    }
}
