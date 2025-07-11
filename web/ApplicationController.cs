/*
 *   _____                                ______
 *  /_   /  ____  ____  ____  _________  / __/ /_
 *    / /  / __ \/ __ \/ __ \/ ___/ __ \/ /_/ __/
 *   / /__/ /_/ / / / / /_/ /\_ \/ /_/ / __/ /_
 *  /____/\____/_/ /_/\__  /____/\____/_/  \__/
 *                   /____/
 *
 * Authors:
 *   钟峰(Popeye Zhong) <zongsoft@qq.com>
 *
 * The MIT License (MIT)
 * 
 * Copyright (C) 2015-2025 Zongsoft Studio <http://zongsoft.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using System;
using System.Linq;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;

using Zongsoft.Web;
using Zongsoft.Common;
using Zongsoft.Services;
using Zongsoft.Components;

namespace Zongsoft.Hosting.Web.Controllers;

[ApiController]
[Route("[controller]")]
public class ApplicationController : ControllerBase
{
	[HttpGet]
	public IActionResult Get()
	{
		var applicationContext = ApplicationContext.Current;
		if(applicationContext == null)
			return this.StatusCode(StatusCodes.Status405MethodNotAllowed);

		return this.Ok(new
		{
			applicationContext.Name,
			applicationContext.Title,
			applicationContext.Version,
			applicationContext.Description,
			Environment = applicationContext.Environment.Name,
		});
	}

	[ControllerName("Events")]
	public sealed class EventController : ControllerBase
	{
		[HttpGet("{name?}")]
		public IActionResult Get(string name = null)
		{
			if(string.IsNullOrWhiteSpace(name))
				return this.Ok(Events.GetEvents());

			var @event = Events.GetEvent(name);
			return @event == null ? this.NoContent() : this.Ok(@event);
		}

		[ActionName("Handlers")]
		[HttpGet("[action]")]
		public IActionResult GetHandlers()
		{
			var applicationContext = ApplicationContext.Current;
			if(applicationContext == null)
				return this.StatusCode(StatusCodes.Status405MethodNotAllowed);

			var handlers = applicationContext.Services.ResolveAll<IHandler<EventContext>>().Select(GetHandlerDescriptor);
			return handlers.Any() ? this.Ok(handlers) : this.NoContent();

			static object GetHandlerDescriptor(object handler)
			{
				if(handler == null)
					return default;

				var handlerType = handler.GetType();

				return new
				{
					Name = handlerType.Name.EndsWith("Handler") ? handlerType.Name[..^7] : handlerType.Name,
					Title = AnnotationUtility.GetDisplayName(handlerType, true),
					Description = AnnotationUtility.GetDescription(handlerType, true)
				};
			}
		}
	}

	[ControllerName("Modules")]
	public sealed class ModuleController : ControllerBase
	{
		[HttpGet("{name?}")]
		public IActionResult Get(string name = null)
		{
			var applicationContext = ApplicationContext.Current;
			if(applicationContext == null)
				return this.StatusCode(StatusCodes.Status405MethodNotAllowed);

			if(string.IsNullOrEmpty(name) || name == "*")
				return this.Ok(applicationContext.Modules.Select(GetApplicationModule).Where(p => p != null));

			if(applicationContext.Modules.TryGetValue(name, out var applicationModule))
				return this.Ok(GetApplicationModule(applicationModule));
			else
				return this.NotFound();

			static object GetApplicationModule(IApplicationModule module)
			{
				if(module == null)
					return null;

				var events = module.GetEvents().Select(@event => new
				{
					Name = @event.QualifiedName,
					@event.Title,
					@event.Description,
				});

				return new
				{
					module.Name,
					module.Title,
					module.Version,
					module.Description,
					Events = events != null && events.Any() ? events : null,
				};
			}
		}

		[ActionName("Services")]
		[HttpGet("[action]/{name?}")]
		[HttpGet("{module}/[action]/{name?}")]
		public IActionResult GetServices(string module, string name = null)
		{
			if(!ApplicationContext.Current.Properties.TryGetValue<ControllerServiceDescriptorCollection>(out var descriptors))
				return this.NotFound();

			if(string.IsNullOrEmpty(module) || module == "*")
			{
				if(string.IsNullOrEmpty(name) || name == "*")
					return this.Ok(descriptors.Select(ControllerUtility.Serializable));

				return descriptors.TryGetValue(name, out var descriptor) ? this.Ok(descriptor.Serializable()) : this.NotFound();
			}
			else
			{
				if(string.IsNullOrEmpty(name) || name == "*")
					return this.Ok(descriptors.Where(descriptor => string.Equals(descriptor.Module, module, StringComparison.OrdinalIgnoreCase)).Select(ControllerUtility.Serializable));

				return descriptors.TryGetValue(module, name, out var descriptor) ? this.Ok(descriptor.Serializable()) : this.NotFound();
			}
		}
	}
}
