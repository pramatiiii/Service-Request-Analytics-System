"""
models/service_request.py
==========================
Defines the ServiceRequest class — a blueprint for a single service ticket.

What is a 'model'?
In software, a model is a class that represents one real-world entity.
Here, one ServiceRequest = one row in the CSV = one repair ticket.
This file only describes what a service request IS (its data).
It does NOT do any analysis or output — that lives in other files.
"""


class ServiceRequest:
    """
    Represents a single service request record.

    Think of this class as a labelled box:
    instead of passing 10 separate variables around the program,
    we bundle them into one clean object — e.g. sr.priority instead of priority_dict['priority'].

    This is called ENCAPSULATION — a core OOP (Object-Oriented Programming) principle.
    """

    def __init__(
        self,
        sr_id,
        asset_id,
        customer_name,
        machine_type,
        reported_date,
        priority,
        status,
        technician,
        resolution_time_hours,
        failure_category,
    ):
        """
        Constructor — runs automatically when a new ServiceRequest object is created.

        Parameters
        ----------
        sr_id                 : unique ticket identifier, e.g. "SR001"
        asset_id              : which machine asset is involved, e.g. "AST042"
        customer_name         : name of the customer/company
        machine_type          : type of machine needing service
        reported_date         : date the issue was reported (string "YYYY-MM-DD")
        priority              : urgency level — "High", "Medium", or "Low"
        status                : current state — "Open", "In Progress", or "Completed"
        technician            : name of the assigned technician
        resolution_time_hours : how many hours it took to fix (0 if not yet resolved)
        failure_category      : what type of failure caused the issue
        """

        # Store every parameter as an instance attribute using 'self'
        # 'self' refers to THIS specific object — not the class, not other objects
        self.sr_id                 = sr_id
        self.asset_id              = asset_id
        self.customer_name         = customer_name
        self.machine_type          = machine_type
        self.reported_date         = reported_date
        self.priority              = priority
        self.status                = status
        self.technician            = technician
        self.resolution_time_hours = int(resolution_time_hours)  # ensure it is always an integer
        self.failure_category      = failure_category

    def __repr__(self):
        """
        Defines what you see when you print() a ServiceRequest object.

        Without this, Python would print something unhelpful like:
            <models.service_request.ServiceRequest object at 0x7f3a...>

        With this, you get something readable:
            ServiceRequest(SR001 | CNC Machine | High | Open)

        __repr__ is called a 'dunder method' (double underscore on both sides).
        """
        return (
            f"ServiceRequest("
            f"{self.sr_id} | "
            f"{self.machine_type} | "
            f"{self.priority} | "
            f"{self.status})"
        )
