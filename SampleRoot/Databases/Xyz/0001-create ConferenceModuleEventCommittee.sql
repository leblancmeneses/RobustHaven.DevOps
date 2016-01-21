GO
/****** Object:  Table [dbo].[ConferenceModuleEventCommittee]    Script Date: 11.03.2014 1:27:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConferenceModuleEventCommittee](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[User_Id] [uniqueidentifier] NULL,
	[Event_Id] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ConferenceModuleEventCommittee] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[ConferenceModuleEventCommittee]  WITH CHECK ADD  CONSTRAINT [FK_ConferenceModuleEventCommittee_ConferenceModuleEvents] FOREIGN KEY([Event_Id])
REFERENCES [dbo].[ConferenceModuleEvents] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ConferenceModuleEventCommittee] CHECK CONSTRAINT [FK_ConferenceModuleEventCommittee_ConferenceModuleEvents]
GO
ALTER TABLE [dbo].[ConferenceModuleEventCommittee]  WITH CHECK ADD  CONSTRAINT [FK_ConferenceModuleEventCommittee_Users] FOREIGN KEY([User_Id])
REFERENCES [dbo].[Users] ([UserId])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ConferenceModuleEventCommittee] CHECK CONSTRAINT [FK_ConferenceModuleEventCommittee_Users]
GO
