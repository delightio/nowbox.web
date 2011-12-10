module Aji
  module ResqueEnqueueInFront
    # Enqueues a job at the front of the queue rather than the back.
    def enqueue_in_front
      Job.create_in_front queue_from_class(klass), klass, *args
    end

    def push_in_front queue, item
      watch_queue queue
      redis.rpush "queue:#{queue}", encode(item)
    end
  end

  module ResqueJobEnqueueInFront
    def create_in_front queue, klass, *args
      if !queue
        raise NoQueueError.new("Jobs must be placed onto a queue.")
      end

      if klass.to_s.empty?
        raise NoClassError.new("Jobs must be given a class.")
      end

      Resque.push_in_front queue, :class => klass.to_s, :args => args
    end
  end
end

Resque.send :extend, Aji::ResqueEnqueueInFront
Resque::Job.send :extend, Aji::ResqueJobEnqueueInFront

