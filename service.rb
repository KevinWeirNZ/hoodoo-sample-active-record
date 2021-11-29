# Top level service class that describes the component interfaces. This is
# run by config.ru. The class must be called "ServiceApplication" (unless
# "config.ru" has been modified).

class ServiceApplication < Hoodoo::Services::Service
    comprised_of PersonInterface
end
